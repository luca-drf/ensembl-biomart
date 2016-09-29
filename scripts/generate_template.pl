#!/bin/env perl
# Copyright [2009-2014] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# $Source$
# $Revision$
# $Date$
# $Author$
#
# Script to populate meta tables for partitioned marts from a set of crude XML templates

use warnings;
use strict;
use DBI;
use Data::Dumper;
use Carp;
use Log::Log4perl qw(:easy);
use DbiUtils;
use MartUtils;
use Cwd;
use File::Copy;
use Getopt::Long;

Log::Log4perl->easy_init($DEBUG);

my $logger = get_logger();

# db params
my $db_host = '127.0.0.1';
my $db_port = 4238;
my $db_user = 'ensrw';
my $db_pwd = 'writ3rp1';
my $mart_db;
my $release;
my $template_template_file = "templates/eg_template_template.xml";
my $ds_name = 'gene';
my $template_file_name = 'templates/dataset_template.xml';
my $description = 'genes';
my $output_dir = undef;
my $species_id_start = undef;

my $is_default = {
                  'hsapiens' => 1,
                  'drerio' => 1,
                  'rnorvegicus' => 1,
                  'mmusculus' => 1,
                  'ggallus' => 1,
                  'athaliana' => 1
};

sub usage {
    print "Usage: $0 [-host <host>] [-port <port>] [-user <user>] [-pass <pwd>] [-mart <mart db>] [-release <e! release number>] [-template <template file path>] [-description <description>] [-dataset <dataset name>] [-ds_template <datanase name template>] [-output_dir <output directory>] [-species_id_start <species id number start>]\n";
    print "-host <host> Default is $db_host\n";
    print "-port <port> Default is $db_port\n";
    print "-user <host> Default is $db_user\n";
    print "-pass <password> Default is top secret unless you know cat\n";
    print "-mart <mart db>\n";
    print "-template <template file path>\n";
    print "-ds_template <ds template>\n";
    print "-dataset <dataset name>\n";
    print "-description <description>\n";
    print "-output_dir <output directory> default is ./output\n";
    print "-release <e! releaseN>\n";
    print "-species_id_start <species id number start> (optional, start number for species_id, avoid duplicated numbers if the core databases are located on two servers. Default is 0)\n";
    exit 1;
};

my $options_okay = GetOptions (
    "host=s"=>\$db_host,
    "port=i"=>\$db_port,
    "user=s"=>\$db_user,
    "pass=s"=>\$db_pwd,
    "release=i"=>\$release,
    "mart=s"=>\$mart_db,
    "dataset=s"=>\$ds_name,
    "template=s"=>\$template_template_file,
    "ds_template=s"=>\$template_file_name,
    "description=s"=>\$description,
    "output_dir=s"=>\$output_dir,
    "species_id_start=s" => \$species_id_start,
    "h|help"=>sub {usage()}
    );

print STDERR "pass: $db_pwd, mart_db, $mart_db, template_template_file, $template_template_file\n";

if(! defined $db_host || ! defined $db_port || ! defined $db_pwd || ! defined $template_template_file || ! defined $mart_db || !defined $release) {
    print STDERR "Missing arguments\n";
    usage();
}

if( !defined $output_dir ){
    $output_dir = "$ENV{PWD}/output";

    unless( -d $output_dir ){ mkdir $output_dir || die "unable to create output directoty $output_dir\n" } 
}

sub write_dataset_xml {
    my $dataset_names = shift;
    my $outdir = shift @_;

    my $fname = $outdir. '/'. $dataset_names->{dataset}. '.xml';
    open my $dataset_file, '>', $fname or croak "Could not open $fname for writing"; 
    open my $template_file, '<', $template_file_name or croak "Could not open $template_file_name";
    while (my $line = <$template_file>) {
	$line =~ s/%name%/$$dataset_names{dataset}_${ds_name}/g;
	$line =~ s/%id%/$$dataset_names{species_id}/g;
	$line =~ s/%des%/$$dataset_names{species_name}/g;
	$line =~ s/%version%/$$dataset_names{version_num}/g;
	print $dataset_file $line;
    }
    close($template_file);
    close($dataset_file);
    `gzip -c $fname > $fname.gz`;
    `md5sum $fname.gz > $fname.gz.md5`;
}

sub write_replace_file {
    my ($template,$output,$placeholders) = @_;
    open my $output_file, '>', $output or croak "Could not open $output";
    open my $template_file, '<', $template or croak "Could not open $template";
    while( my $content = <$template_file>) {
	foreach my $placeholder (keys(%$placeholders)) {
	    my $contents = $placeholders->{$placeholder};
	    if ($content =~ m/$placeholder/) {
		$content =~ s/$placeholder/$contents/;
	    }
	}
	if($content =~ m/(.*tableConstraint=")([^"]+)(".*)/s and $ds_name !~ 'gene_ensembl') {
	    $content = $1 . lc($2) . $3;
	}	    
        print $output_file $content;
    }
    close($output_file);
    close($template_file);
}

sub get_dataset_element {
    my $dataset = shift;
    if ($ds_name !~ 'gene_ensembl'){
        return '<DynamicDataset aliases="mouse_formatter1=,mouse_formatter2=,mouse_formatter3=,species1='.
        $dataset->{species_name}.
          ',species2='.$dataset->{species_uc_name}.
            ',species3='.$dataset->{dataset}.
              ',species4='.$dataset->{short_name}.
                ',collection_path='.$dataset->{colstr}.
                  ',version='.$dataset->{version_num}.
                    #       ',tax_id='.$dataset->{tax_id}.
                    ',link_version='.$dataset->{dataset}.
                      '_'.$release.',default='.$dataset->{default}.'" internalName="'.
                        $dataset->{dataset}.'_'.$ds_name.'"/>'
                      }
    # for ensembl species
    else
      {
        my $species1=ucfirst($dataset->{species_uc_name});
        $species1=~ s/_/ /g;
        my $species5=ucfirst($dataset->{species_uc_name});
        $species5=~ s/_/+/g;
        return '<DynamicDataset aliases="mouse_formatter1=,mouse_formatter2=,mouse_formatter3=,species1='.
          $species1.
            ',species2='.ucfirst($dataset->{species_uc_name}).
              ',species3='.$dataset->{dataset}.
                ',species4='.substr($dataset->{dataset},0,4).
                  ',species5='.$species5.
                    ',collection_path='.$dataset->{colstr}.
                      ',version='.$dataset->{version_num}.
                        ',link_version='.$dataset->{version_num}.
                          ',default='.$dataset->{default}.'" internalName="'.
                            $dataset->{dataset}.'_'.$ds_name.'"/>'
                          }
  }

sub get_dataset_exportable {
  my $dataset = shift;
    my $text = << "EXP_END";
    <Exportable attributes="$dataset->{dataset}_gene" 
	default="1" internalName="$dataset->{dataset}_gene_stable_id" 
	linkName="$dataset->{dataset}_gene_stable_id" 
	name="$dataset->{dataset}_gene_stable_id" type="link"/>
EXP_END
    $text;
}

sub get_dataset_exportable_link {
    my $dataset = shift;
    my $text = << "EXPL_END";
        <AttributeDescription field="homol_id" hideDisplay="true" internalName="$dataset->{dataset}_gene_id" key="gene_id_1020_key" maxLength="128" tableConstraint="homologs_$dataset->{dataset}__dm"/>
EXPL_END
    $text;
}

sub get_dataset_homolog_filter {
    my $dataset = shift;
    my $text = << "HOMOFIL_END";
<Option displayName="Orthologous $dataset->{species_name} Genes" displayType="list" field="homolog_$dataset->{dataset}_bool" hidden="false" internalName="with_$dataset->{dataset}_homolog" isSelectable="true" key="gene_id_1020_key" legal_qualifiers="only,excluded" qualifier="only" style="radio" tableConstraint="main" type="boolean"><Option displayName="Only" hidden="false" internalName="only" value="only" /><Option displayName="Excluded" hidden="false" internalName="excluded" value="excluded" /></Option>
HOMOFIL_END
    $text;
}

sub get_dataset_paralog_filter {
    my $dataset = shift;
    my $text = << "PARAFIL_END";
<Option displayName="Paralogous $dataset->{species_name} Genes" displayType="list" field="paralog_$dataset->{dataset}_bool" hidden="false" internalName="with_$dataset->{dataset}_paralog" isSelectable="true" key="gene_id_1020_key" legal_qualifiers="only,excluded" qualifier="only" style="radio" tableConstraint="main" type="boolean"><Option displayName="Only" hidden="false" internalName="only" isSelectable="true" value="only" /><Option displayName="Excluded" hidden="false" internalName="excluded" isSelectable="true" value="excluded" /></Option>
PARAFIL_END
    $text;
}

sub get_dataset_homoeolog_filter {
    my $dataset = shift;
    my $text = << "HOMOEOFIL_END";
<Option displayName="Homoeologous $dataset->{species_name} Genes" displayType="list" field="homoeolog_$dataset->{dataset}_bool" hidden="false" internalName="with_$dataset->{dataset}_homoeolog" isSelectable="true" key="gene_id_1020_key" legal_qualifiers="only,excluded" qualifier="only" style="radio" tableConstraint="main" type="boolean"><Option displayName="Only" hidden="false" internalName="only" isSelectable="true" value="only" /><Option displayName="Excluded" hidden="false" internalName="excluded" isSelectable="true" value="excluded" /></Option>
HOMOEOFIL_END
    $text;
}


sub get_dataset_homolog_attribute {
    my $dataset = shift;
    my $text;
    # Homolog attribute section of the EG gene mart
    if ($ds_name !~ 'gene_ensembl'){
    $text = << "HOMOATT_END";
    <AttributeCollection displayName="$dataset->{species_name} Orthologs" internalName="homolog_$dataset->{dataset}">
    <AttributeDescription displayName="$dataset->{species_name} gene stable ID" field="stable_id_4016_r2" internalName="$dataset->{dataset}_gene" key="gene_id_1020_key" linkoutURL="exturl1|/$dataset->{species_uc_name}/Gene/Summary?g=%s" maxLength="128" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="$dataset->{species_name} protein stable ID" field="stable_id_4016_r3" internalName="$dataset->{dataset}_homolog_ensembl_peptide" key="gene_id_1020_key" maxLength="128" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="$dataset->{species_name} chromosome/scaffold" field="chr_name_4016_r2" internalName="$dataset->{dataset}_chromosome" key="gene_id_1020_key" maxLength="40" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="$dataset->{species_name} start (bp)" field="chr_start_4016_r2" internalName="$dataset->{dataset}_chrom_start" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="$dataset->{species_name} end (bp)" field="chr_end_4016_r2" internalName="$dataset->{dataset}_chrom_end" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="Representative protein or transcript ID" field="stable_id_4016_r1" internalName="homolog_$dataset->{dataset}__dm_stable_id_4016_r1" key="gene_id_1020_key" maxLength="128" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="Ancestor" field="node_name_40192" internalName="$dataset->{dataset}_homolog_ancestor" key="gene_id_1020_key" maxLength="40" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="Homology type" field="description_4014" internalName="$dataset->{dataset}_orthology_type" key="gene_id_1020_key" maxLength="25" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="% identity" field="perc_id_4015" internalName="$dataset->{dataset}_homolog_perc_id" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="$dataset->{species_name} % identity" field="perc_id_4015_r1" internalName="$dataset->{dataset}_homolog_perc_id_r1" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="$dataset->{species_name} Gene-order conservation score" field="goc_score_4014" internalName="$dataset->{dataset}_homolog_goc_score" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="$dataset->{species_name} Whole-genome alignment coverage" field="wga_coverage_4014" internalName="$dataset->{dataset}_homolog_wga_coverage" key="gene_id_1020_key" maxLength="5" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="dN" field="dn_4014" internalName="$dataset->{dataset}_homolog_dn" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="dS" field="ds_4014" internalName="$dataset->{dataset}_homolog_ds" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="Orthology confidence [0 low, 1 high]" field="is_high_confidence_4014" internalName="$dataset->{dataset}_homolog_is_high_confidence" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="Bootstrap/Duplication Confidence Score Type" field="tag_4060" hidden="true" internalName="homolog_$dataset->{dataset}__dm_tag_4060" key="gene_id_1020_key" maxLength="50" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    <AttributeDescription displayName="Bootstrap/Duplication Confidence Score" field="value_4060" hidden="true" internalName="homolog_$dataset->{dataset}__dm_value_4060" key="gene_id_1020_key" maxLength="255" tableConstraint="homolog_$dataset->{dataset}__dm"/>
    </AttributeCollection>
HOMOATT_END
    $text;
    }
    # Homologue attribute section of the e! ensembl gene mart
    else{
      $text = << "HOMOATT_END";
      <AttributeCollection displayName="$dataset->{species_name} Orthologues" internalName="homolog_$dataset->{dataset}">
      <AttributeDescription displayName="$dataset->{species_name} Ensembl Gene ID" field="stable_id_4016_r2" internalName="$dataset->{dataset}_homolog_ensembl_gene" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/Gene/Summary?g=%s" maxLength="128" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} associated gene name" field="display_label_40273_r1" internalName="$dataset->{dataset}_homolog_associated_gene_name" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/Gene/Summary?g=%s|$dataset->{dataset}_homolog_ensembl_gene" maxLength="128" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Query Ensembl Protein or Transcript ID" field="stable_id_4016_r1" internalName="$dataset->{dataset}_homolog_canonical_transcript_protein" key="gene_id_1020_key" maxLength="128" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Ensembl Protein or Transcript ID" field="stable_id_4016_r3" internalName="$dataset->{dataset}_homolog_ensembl_peptide" key="gene_id_1020_key" maxLength="128" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Chromosome Name" field="chr_name_4016_r2" internalName="$dataset->{dataset}_homolog_chromosome" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/mapview?chr=%s" maxLength="40" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Chromosome start (bp)" field="chr_start_4016_r2" internalName="$dataset->{dataset}_homolog_chrom_start" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/contigview?chr=%s&amp;vc_start=%s&amp;vc_end=%s|$dataset->{dataset}_homolog_chromosome|$dataset->{dataset}_homolog_chrom_start|$dataset->{dataset}_homolog_chrom_end"  maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Chromosome end (bp)" field="chr_end_4016_r2" internalName="$dataset->{dataset}_homolog_chrom_end" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/contigview?chr=%s&amp;vc_start=%s&amp;vc_end=%s|$dataset->{dataset}_homolog_chromosome|$dataset->{dataset}_homolog_chrom_start|$dataset->{dataset}_homolog_chrom_end" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} homology type" field="description_4014" internalName="$dataset->{dataset}_homolog_orthology_type" key="gene_id_1020_key" maxLength="25" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Last common ancestor with $dataset->{species_name}" field="node_name_40192" internalName="$dataset->{dataset}_homolog_subtype" key="gene_id_1020_key" maxLength="255" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} orthology confidence [0 low, 1 high]" field="is_high_confidence_4014" internalName="$dataset->{dataset}_homolog_orthology_confidence" key="gene_id_1020_key" linkoutURL="exturl|/info/genome/compara/homology_method.html#homology_types" maxLength="1" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Gene-order conservation score" field="goc_score_4014" internalName="$dataset->{dataset}_homolog_goc_score" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Whole-genome alignment coverage" field="wga_coverage_4014" internalName="$dataset->{dataset}_homolog_wga_coverage" key="gene_id_1020_key" maxLength="5" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="%id. target $dataset->{species_name} gene identical to query gene" field="perc_id_4015" internalName="$dataset->{dataset}_homolog_perc_id" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="%id. query gene identical to target $dataset->{species_name} gene" field="perc_id_4015_r1" internalName="$dataset->{dataset}_homolog_perc_id_r1" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="dN with $dataset->{species_name}" field="dn_4014" internalName="$dataset->{dataset}_homolog_dn" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="dS with $dataset->{species_name}" field="ds_4014" internalName="$dataset->{dataset}_homolog_ds" key="gene_id_1020_key" maxLength="10" tableConstraint="homolog_$dataset->{dataset}__dm"/>
      </AttributeCollection>
HOMOATT_END
      $text;
    }
}

sub get_dataset_paralog_attribute {
    my $dataset = shift;
    my $text;
    # Paralog attribute setion of the EG gene mart
    if ($ds_name !~ 'gene_ensembl'){
      $text = << "PARAATT_END";
      <AttributeCollection displayName="$dataset->{species_name} Paralogs" internalName="paralogs_$dataset->{dataset}">
      <AttributeDescription displayName="Paralog gene stable ID" field="stable_id_4016_r2" internalName="$dataset->{dataset}_paralog_gene" key="gene_id_1020_key" linkoutURL="exturl1|/*species2*/Gene/Summary?g=%s" maxLength="140" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Paralog protein stable ID" field="stable_id_4016_r3" internalName="$dataset->{dataset}_paralog_paralog_ensembl_peptide" key="gene_id_1020_key" maxLength="40" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Paralog chromosome/scaffold" field="chr_name_4016_r2" internalName="$dataset->{dataset}_paralog_chromosome" key="gene_id_1020_key" maxLength="40" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Paralog start (bp)" field="chr_start_4016_r2" internalName="$dataset->{dataset}_paralog_chrom_start" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Paralog end (bp)" field="chr_end_4016_r2" internalName="$dataset->{dataset}_paralog_chrom_end" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Representative protein stable ID" field="stable_id_4016_r1" internalName="$dataset->{dataset}_paralog_ensembl_peptide" key="gene_id_1020_key" maxLength="40" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Ancestor" field="node_name_40192" internalName="$dataset->{dataset}_paralog_ancestor" key="gene_id_1020_key" maxLength="40" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Homology type" field="description_4014" internalName="paralog_$dataset->{dataset}__dm_description_4014" key="gene_id_1020_key" maxLength="25" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="% identity" field="perc_id_4015" internalName="paralog_$dataset->{dataset}__dm_perc_id_4015" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Paralog % identity" field="perc_id_4015_r1" internalName="paralog_$dataset->{dataset}__dm_perc_id_4015_r1" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="dN" field="dn_4014" internalName="paralog_$dataset->{dataset}__dm_dn_4014" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="dS" field="ds_4014" internalName="paralog_$dataset->{dataset}__dm_ds_4014" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Paralogy confidence [0 low, 1 high]" field="is_high_confidence_4014" internalName="$dataset->{dataset}_paralog_is_high_confidence" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Bootstrap/Duplication Confidence Score Type" field="tag_4060" internalName="$dataset->{dataset}_tag" key="gene_id_1020_key" maxLength="50" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Bootstrap/Duplication Confidence Score" field="value_4060" internalName="$dataset->{dataset}_value" key="gene_id_1020_key" maxLength="255" tableConstraint="paralog_$dataset->{dataset}__dm"/>  
      </AttributeCollection>
PARAATT_END
      $text;
    }
    # Paralogue attribute section of the e! gene mart
    else{
      $text = << "PARAATT_END";
      <AttributeCollection displayName="$dataset->{species_name} Paralogues" internalName="paralogs_$dataset->{dataset}">
      <AttributeDescription displayName="$dataset->{species_name} Paralogue Ensembl Gene ID" field="stable_id_4016_r2" internalName="$dataset->{dataset}_paralog_ensembl_gene" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/Gene/Summary?g=%s" maxLength="140" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Paralogue associated gene name" field="display_label_40273_r1" internalName="$dataset->{dataset}_paralog_associated_gene_name" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/Gene/Summary?g=%s|$dataset->{dataset}_paralog_ensembl_gene" maxLength="128" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Query Ensembl Protein or Transcript ID" field="stable_id_4016_r1" internalName="$dataset->{dataset}_paralog_canonical_transcript_protein" key="gene_id_1020_key" maxLength="40" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Paralogue Ensembl Protein or Transcript ID" field="stable_id_4016_r3" internalName="$dataset->{dataset}_paralog_ensembl_peptide" key="gene_id_1020_key" maxLength="40" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Paralogue Chromosome Name" field="chr_name_4016_r2" internalName="$dataset->{dataset}_paralog_chromosome" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/mapview?chr=%s"  maxLength="40" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Paralogue Chromosome Start (bp)" field="chr_start_4016_r2" internalName="$dataset->{dataset}_paralog_chrom_start" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/contigview?chr=%s&amp;vc_start=%s&amp;vc_end=%s|$dataset->{dataset}_paralog_chromosome|$dataset->{dataset}_paralog_chrom_start|$dataset->{dataset}_paralog_chrom_end" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} Paralogue Chromosome End (bp)" field="chr_end_4016_r2" internalName="$dataset->{dataset}_paralog_chrom_end" key="gene_id_1020_key" linkoutURL="exturl|/$dataset->{species_uc_name}/contigview?chr=%s&amp;vc_start=%s&amp;vc_end=%s|$dataset->{dataset}_paralog_chromosome|$dataset->{dataset}_paralog_chrom_start|$dataset->{dataset}_paralog_chrom_end" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} homology type" field="description_4014" internalName="$dataset->{dataset}_paralog_orthology_type" key="gene_id_1020_key" maxLength="25" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="Last common ancestor with $dataset->{species_name}" field="node_name_40192" internalName="$dataset->{dataset}_paralog_subtype" key="gene_id_1020_key" maxLength="255" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="$dataset->{species_name} paralogy confidence [0 low, 1 high]" field="is_high_confidence_4014" internalName="$dataset->{dataset}_paralog_paralogy_confidence" key="gene_id_1020_key" linkoutURL="exturl|/info/genome/compara/homology_method.html#homology_types" maxLength="1" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="%id. target $dataset->{species_name} gene identical to query gene" field="perc_id_4015" internalName="$dataset->{dataset}_paralog_perc_id" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="%id. query gene identical to target $dataset->{species_name} gene" field="perc_id_4015_r1" internalName="$dataset->{dataset}_paralog_perc_id_r1" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="dN with $dataset->{species_name}" field="dn_4014" internalName="$dataset->{dataset}_paralog_dn" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      <AttributeDescription displayName="dS with $dataset->{species_name}" field="ds_4014" internalName="$dataset->{dataset}_paralog_ds" key="gene_id_1020_key" maxLength="10" tableConstraint="paralog_$dataset->{dataset}__dm"/>
      </AttributeCollection>
PARAATT_END
      $text;
    }
}

sub get_dataset_homoeolog_attribute {
    my $dataset = shift;
    my $text = << "HOMOEOATT_END";
      <AttributeCollection displayName="$dataset->{species_name} Homoeologs" internalName="homoeologs_$dataset->{dataset}">
        <AttributeDescription displayName="Homoeolog gene stable ID" field="stable_id_4016_r2" internalName="$dataset->{dataset}_homoeolog_gene" key="gene_id_1020_key" linkoutURL="exturl1|/*species2*/Gene/Summary?g=%s" maxLength="140" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Homoeolog protein stable ID" field="stable_id_4016_r3" internalName="$dataset->{dataset}_homoeolog_homoeolog_ensembl_peptide" key="gene_id_1020_key" maxLength="40" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Homoeolog chromosome/scaffold" field="chr_name_4016_r2" internalName="$dataset->{dataset}_homoeolog_chromosome" key="gene_id_1020_key" linkoutURL="exturl1|/*species2*/Location/View?r=$dataset->{dataset}_homoeolog_chromosome" maxLength="40" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Homoeolog start (bp)" field="chr_start_4016_r2" internalName="$dataset->{dataset}_homoeolog_chrom_start" key="gene_id_1020_key" linkoutURL="exturl1|/*species2*/Location/View?r=$dataset->{dataset}_homoeolog_chromosome:$dataset->{dataset}_homoeolog_chrom_start-$dataset->{dataset}_homoeolog_chrom_end" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Homoeolog end (bp)" field="chr_end_4016_r2" internalName="$dataset->{dataset}_homoeolog_chrom_end" key="gene_id_1020_key" linkoutURL="exturl1|/*species2*/Location/View?r=$dataset->{dataset}_homoeolog_chromosome:$dataset->{dataset}_homoeolog_chrom_start-$dataset->{dataset}_homoeolog_chrom_end" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Representative protein stable ID" field="stable_id_4016_r1" internalName="$dataset->{dataset}_homoeolog_ensembl_peptide" key="gene_id_1020_key" maxLength="40" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Ancestor" field="node_name_40192" internalName="$dataset->{dataset}_homoeolog_ancestor" key="gene_id_1020_key" maxLength="40" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Homology type" field="description_4014" internalName="homoeolog_$dataset->{dataset}__dm_description_4014" key="gene_id_1020_key" maxLength="25" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="% identity" field="perc_id_4015" internalName="homoeolog_$dataset->{dataset}__dm_perc_id_4015" key="gene_id_1020_key" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Homoeolog % identity" field="perc_id_4015_r1" internalName="homoeolog_$dataset->{dataset}__dm_perc_id_4015_r1" key="gene_id_1020_key" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Gene-order conservation score" field="goc_score_4014" internalName="homoeolog_$dataset->{dataset}__dm_goc_score_4014" key="gene_id_1020_key" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Whole-genome alignment coverage" field="wga_coverage_4014" internalName="homoeolog_$dataset->{dataset}__dm_wga_coverage_4014" key="gene_id_1020_key" maxLength="5" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="dN" field="dn_4014" internalName="homoeolog_$dataset->{dataset}__dm_dn_4014" key="gene_id_1020_key" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="dS" field="ds_4014" internalName="homoeolog_$dataset->{dataset}__dm_ds_4014" key="gene_id_1020_key" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Homoeology confidence [0 low, 1 high]" field="is_high_confidence_4014" internalName="$dataset->{dataset}_homoeolog_is_high_confidence" key="gene_id_1020_key" maxLength="10" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Bootstrap/Duplication Confidence Score Type" field="tag_4060" internalName="$dataset->{dataset}_tag" key="gene_id_1020_key" maxLength="50" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
        <AttributeDescription displayName="Bootstrap/Duplication Confidence Score" field="value_4060" internalName="$dataset->{dataset}_value" key="gene_id_1020_key" maxLength="255" tableConstraint="homoeolog_$dataset->{dataset}__dm"/>
      </AttributeCollection>
HOMOEOATT_END
    $text;
}


sub write_template_xml {
    my $datasets = shift;
    my $outdir = shift @_;

    my $datasets_text='';
    my $homology_filters_text='';
    my $homology_attributes_text='';
    my $paralogy_attributes_text='';
    my $homoeology_attributes_text='';
    my $exportables_text='';
    my $exportables_link_text='';
    my $poly_attrs_text = '';
    foreach my $dataset (@$datasets) {
      print STDERR "Generating elems for ".$dataset->{dataset}."\n";
      $datasets_text .= get_dataset_element($dataset);
      $exportables_text .= get_dataset_exportable($dataset);
      $exportables_link_text .= get_dataset_exportable_link($dataset);
      $homology_filters_text .= get_dataset_homolog_filter($dataset);
      $homology_filters_text .= get_dataset_paralog_filter($dataset);

      $homology_attributes_text .= get_dataset_homolog_attribute($dataset);
      $paralogy_attributes_text .= get_dataset_paralog_attribute($dataset);
      
      if ($dataset->{dataset} =~ /taestivum/) {
	  
	  # Add homoeolog filters and attributes only for bread wheat
	  
	  $homology_filters_text .= get_dataset_homoeolog_filter($dataset);
	  $homoeology_attributes_text .= get_dataset_homoeolog_attribute($dataset);
      }
    }
    my %placeholders = (
    '.*<Replace id="datasets"/>'=>$datasets_text,
    '.*<Replace id="homology_filters"/>'=>$homology_filters_text,
    '.*<Replace id="homology_attributes"/>'=>$homology_attributes_text,
    '.*<Replace id="paralogy_attributes"/>'=>$paralogy_attributes_text,
    '.*<Replace id="homoeology_attributes"/>'=>$homoeology_attributes_text,
    '.*<Replace id="exportables"/>'=>$exportables_text,
    '.*<Replace id="exportables_link"/>'=>$exportables_link_text,
    '.*<Replace id="poly_attrs"/>'=>$poly_attrs_text
    );
    write_replace_file($template_template_file,"$outdir/template.xml",\%placeholders);
    `gzip -c $outdir/template.xml > $outdir/template.xml.gz`;
}


sub update_meta_file {
    my ($template,$output,$placeholder,$prefix,$suffix,$separator,$datasets,$ds_closure) = @_;  
    my $datasets_text=$prefix;  
    my $first=0;
    foreach my $dataset (@$datasets) {
	if($first>0) {
	    $datasets_text .= $separator;
	}
	my $dst = &$ds_closure($dataset);
	$datasets_text .= $dst;
	$first++;
    }
    $datasets_text.=$suffix;
    write_replace_file($template,$output,$placeholder,$datasets_text);
}

my $table_args ="ENGINE=MyISAM DEFAULT CHARSET=latin1";
sub create_metatable {
    my ($db_handle,$table_name,$cols) = @_[0,1,2];
    drop_and_create_table($db_handle,$table_name,$cols,$table_args);
}

sub write_metatables {
    my ($mart_handle, $datasets,$outdir) = @_[0,1,2];
    my $pwd = &Cwd::cwd();

    $logger->info("Creating meta tables");

    # create tables
    create_metatable($mart_handle,'meta_version__version__main',
		     ['version varchar(10) default NULL']);
    create_metatable($mart_handle,'meta_template__xml__dm',
		     ['template varchar(100) default NULL',
		      'compressed_xml longblob',
		      'UNIQUE KEY template (template)']);
    create_metatable($mart_handle,'meta_conf__xml__dm',
		     ['dataset_id_key int(11) NOT NULL',
		      'xml longblob',
		      'compressed_xml longblob',
		      'message_digest blob',
		      'UNIQUE KEY dataset_id_key (dataset_id_key)']);
    create_metatable($mart_handle,'meta_conf__user__dm',
		     ['dataset_id_key int(11) default NULL',
		      'mart_user varchar(100) default NULL',
		      'UNIQUE KEY dataset_id_key (dataset_id_key,mart_user)']);
    create_metatable($mart_handle,'meta_conf__interface__dm',
		     ['dataset_id_key int(11) default NULL',
		      'interface varchar(100) default NULL',
		      'UNIQUE KEY dataset_id_key (dataset_id_key,interface)']);
    create_metatable($mart_handle,'meta_template__template__main',
		     ['dataset_id_key int(11) NOT NULL',
		      'template varchar(100) NOT NULL']);
    create_metatable($mart_handle,'meta_conf__dataset__main',[ 
			 'dataset_id_key int(11) NOT NULL',
			 'dataset varchar(100) default NULL',
			 'display_name varchar(200) default NULL',
			 'description varchar(200) default NULL',
			 'type varchar(20) default NULL',
			 'visible int(1) unsigned default NULL',
			 'version varchar(128) default NULL',
			 'modified timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP',
			 'UNIQUE KEY dataset_id_key (dataset_id_key)']);

    $logger->info("Populating template tables");
    # populate template tables
    ## meta_version__version__main
    $mart_handle->do("INSERT INTO meta_version__version__main VALUES ('0.7')");
    ## meta_template__xml__dm
    my $sth = $mart_handle->prepare('INSERT INTO meta_template__xml__dm VALUES (?,?)');
    $sth->execute($ds_name, file_to_bytes("$outdir/template.xml.gz")) 
		  or croak "Could not load file into meta_template__xml__dm";
    $sth->finish();
 
    $logger->info("Populating dataset tables");
    my $meta_conf__xml__dm = $mart_handle->prepare('INSERT INTO meta_conf__xml__dm VALUES (?,?,?,?)');
    my $meta_conf__user__dm = $mart_handle->prepare('INSERT INTO meta_conf__user__dm VALUES(?,\'default\')');
    my $meta_conf__interface__dm = $mart_handle->prepare('INSERT INTO meta_conf__interface__dm VALUES(?,\'default\')');
    my $meta_conf__dataset__main = $mart_handle->prepare("INSERT INTO meta_conf__dataset__main(dataset_id_key,dataset,display_name,description,type,visible,version) VALUES(?,?,?,'Ensembl $description','TableSet',1,?)");
    my $meta_template__template__main = $mart_handle->prepare('INSERT INTO meta_template__template__main VALUES(?,?)');
    # populate dataset tables
    my $speciesId;
    foreach my $dataset (@$datasets) { 
	my $speciesId = $dataset->{species_id};
	# meta_conf__xml__dm
	$logger->info("Writing metadata for species ".$dataset->{species_id});
	$meta_conf__xml__dm->execute($speciesId,
				     file_to_bytes("$outdir/$dataset->{dataset}.xml"),
				     file_to_bytes("$outdir/$dataset->{dataset}.xml.gz"),
				     file_to_bytes("$outdir/$dataset->{dataset}.xml.gz.md5")
	    ) or croak "Could not update meta_conf__xml__dm";
	# meta_conf__user__dm
	$meta_conf__user__dm->execute($speciesId) 
	    or croak "Could not update meta_conf__user__dm";
	# meta_conf__interface__dm
	$meta_conf__interface__dm->execute($speciesId)  
	    or croak "Could not update meta_conf__interface__dm";
	# meta_conf__dataset__main 
	print Dumper($dataset);
	$meta_conf__dataset__main->execute(
	    $speciesId,
	    "$dataset->{dataset}_$ds_name",
	    "$dataset->{species_name} $description ($dataset->{version_num})",
	    $dataset->{version_num}) or croak "Could not update meta_conf__dataset__main";
	# meta_template__template__main
	$meta_template__template__main->execute($speciesId,$ds_name)  
	    or croak "Could not update meta_template__template__dm";
    }
    $meta_conf__xml__dm->finish();
    $meta_conf__user__dm->finish();
    $meta_conf__interface__dm->finish();
    $meta_conf__dataset__main->finish();
    $meta_template__template__main->finish();
    $logger->info("Population complete");
}

sub get_short_name {
    my ($db_name,$species_id) = @_;
    return uc($species_id);
} 

sub get_version {
    my $ens_db = shift;
    $ens_db =~ m/^.*_([0-9]+[a-z]*)$/;
    $1;
}

my $mart_string = "DBI:mysql:$mart_db:$db_host:$db_port";
my $mart_handle = DBI->connect($mart_string, $db_user, $db_pwd,
			       { RaiseError => 1 }
    ) or croak "Could not connect to $mart_string";

my @datasets = ();
my $dataset_sth = $mart_handle->prepare('SELECT src_dataset,src_db,species_id,species_name,version,collection,sql_name FROM dataset_names WHERE name=?');

# get names of datasets from names table
my $i;
if (defined $species_id_start)
{
 $i=$species_id_start;
}
else{
  $i=0;
}
foreach my $dataset (get_dataset_names($mart_handle)) {
    $logger->info("Processing $dataset");
    # get other naming info from names table
    my %dataset_names = ();
    $dataset_names{dataset}=$dataset;
    ($dataset_names{baseset}, $dataset_names{src_db},$dataset_names{species_id},$dataset_names{species_name},$dataset_names{version_num},$dataset_names{collection},$dataset_names{species_uc_name}) = get_row($dataset_sth,$dataset);
    if(!$dataset_names{species_id}) {
	$dataset_names{species_id} = ++$i;
    }
    if(!$dataset_names{species_uc_name}) {
	$dataset_names{species_uc_name} = $dataset_names{species_name};
	$dataset_names{species_uc_name} =~ s/\s+/_/g;
    }
    $dataset_names{short_name} = get_short_name($dataset_names{species_name},$dataset_names{species_id});
    $dataset_names{colstr} = '';
    if(defined $dataset_names{collection}) {
	$dataset_names{colstr} = '/'.$dataset_names{collection};
    }
    $dataset_names{compara}=substr($dataset_names{baseset},0,4);
    #$logger->debug(join(',',values(%dataset_names)));

    if($is_default->{$dataset}) {
      $dataset_names{default} = 'true';
    } else {
      $dataset_names{default} = 'false';
    }

    push(@datasets,\%dataset_names);
    write_dataset_xml(\%dataset_names , $output_dir);
}
$dataset_sth->finish();

@datasets = sort {$a->{species_name} cmp $b->{species_name}} @datasets;

# 2. write template files
write_template_xml(\@datasets , $output_dir);


write_metatables($mart_handle, \@datasets , $output_dir);

$mart_handle->disconnect() or croak "Could not close handle to $mart_string";
