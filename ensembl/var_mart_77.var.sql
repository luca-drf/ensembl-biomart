create table VAR_MART_DB.TEMP0 as select a.clinical_significance as clinical_significance_2025,a.minor_allele_freq as minor_allele_freq_2025,a.source_id as source_id_2025,a.name as name_2025,a.ancestral_allele as ancestral_allele_2025,a.minor_allele as minor_allele_2025,a.variation_id as variation_id_2025_key,a.minor_allele_count as minor_allele_count_2025 from VAR_DB.variation as a where a.somatic=0;
create index I_0 on VAR_MART_DB.TEMP0(source_id_2025);
create table VAR_MART_DB.TEMP1 as select a.*,b.description as description_2021,b.name as name_2021 from VAR_MART_DB.TEMP0 as a left join VAR_DB.source as b on a.source_id_2025=b.source_id;
drop table VAR_MART_DB.TEMP0;
create index I_1 on VAR_MART_DB.TEMP1(variation_id_2025_key);
create table VAR_MART_DB.TEMP2 as select a.*,b.evidence as evidence_2025 from VAR_MART_DB.TEMP1 as a left join VAR_DB.MTMP_evidence as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP1;
alter table VAR_MART_DB.TEMP2 drop column source_id_2025;
create index I_2 on VAR_MART_DB.TEMP2(name_2025);
create index I_3 on VAR_MART_DB.TEMP2(name_2021);
create index I_4 on VAR_MART_DB.TEMP2(evidence_2025);
create index I_5 on VAR_MART_DB.TEMP2(clinical_significance_2025);
rename table VAR_MART_DB.TEMP2 to VAR_MART_DB.SPECIES_ABBREV_snp__variation__main;
create index I_6 on VAR_MART_DB.SPECIES_ABBREV_snp__variation__main(variation_id_2025_key);
create table VAR_MART_DB.TEMP3 as select a.description as description_2021,a.source_id as source_id_2021,a.name as name_2021 from VAR_DB.source as a;
create index I_7 on VAR_MART_DB.TEMP3(source_id_2021);
create table VAR_MART_DB.TEMP4 as select a.*,b.subsnp_id as subsnp_id_2030,b.name as name_2030,b.variation_id as variation_id_2025_key,b.variation_synonym_id as variation_synonym_id_2030 from VAR_MART_DB.TEMP3 as a inner join VAR_DB.variation_synonym as b on a.source_id_2021=b.source_id;
drop table VAR_MART_DB.TEMP3;
create index I_8 on VAR_MART_DB.TEMP4(variation_id_2025_key);
create table VAR_MART_DB.TEMP6 as select a.* from VAR_MART_DB.TEMP4 as a inner join VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP4;
create index I_9 on VAR_MART_DB.TEMP6(variation_id_2025_key);
create table VAR_MART_DB.TEMP7 as select a.variation_id_2025_key,b.description_2021,b.source_id_2021,b.variation_synonym_id_2030,b.name_2030,b.name_2021,b.subsnp_id_2030 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP6 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP6;
alter table VAR_MART_DB.TEMP7 drop column variation_synonym_id_2030;
alter table VAR_MART_DB.TEMP7 drop column subsnp_id_2030;
create index I_10 on VAR_MART_DB.TEMP7(name_2030);
create index I_11 on VAR_MART_DB.TEMP7(name_2021);
rename table VAR_MART_DB.TEMP7 to VAR_MART_DB.SPECIES_ABBREV_snp__variation_synonym__dm;
create index I_12 on VAR_MART_DB.SPECIES_ABBREV_snp__variation_synonym__dm(variation_id_2025_key);
create table VAR_MART_DB.TEMP8 as select a.variation_id_2025_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_13 on VAR_MART_DB.TEMP8(variation_id_2025_key);
create table VAR_MART_DB.TEMP9 as select a.*,b.subsnp_id as subsnp_id_2023,b.allele_1 as allele_1_2023,b.allele_2 as allele_2_2023,b.individual_id as individual_id_2023 from VAR_MART_DB.TEMP8 as a left join VAR_DB.tmp_individual_genotype_single_bp as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP8;
create index I_14 on VAR_MART_DB.TEMP9(individual_id_2023);
create table VAR_MART_DB.TEMP11 as select a.*,b.individual_type_id as individual_type_id_2019,b.name as name_2019 from VAR_MART_DB.TEMP9 as a inner join VAR_DB.individual as b on a.individual_id_2023=b.individual_id and (b.display in ("REFERENCE","DEFAULT","DISPLAYABLE","MARTDISPLAYABLE"));
drop table VAR_MART_DB.TEMP9;
create index I_15 on VAR_MART_DB.TEMP11(individual_type_id_2019);
create table VAR_MART_DB.TEMP13 as select a.* from VAR_MART_DB.TEMP11 as a left join VAR_DB.individual_type as b on a.individual_type_id_2019=b.individual_type_id;
drop table VAR_MART_DB.TEMP11;
create table VAR_MART_DB.TEMP14 as select individual_id_2023,individual_type_id_2019,name_2019,allele_2_2023,variation_id_2025_key,subsnp_id_2023,allele_1_2023,concat(allele_1_2023, '|', allele_2_2023) as allele from VAR_MART_DB.TEMP13;
drop table VAR_MART_DB.TEMP13;
create index I_16 on VAR_MART_DB.TEMP14(variation_id_2025_key);
create table VAR_MART_DB.TEMP15 as select a.variation_id_2025_key,b.individual_id_2023,b.subsnp_id_2023,b.individual_type_id_2019,b.allele,b.allele_2_2023,b.allele_1_2023,b.name_2019 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP14 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP14;
create table VAR_MART_DB.TEMP16 as select distinct individual_id_2023,name_2019,allele,variation_id_2025_key from VAR_MART_DB.TEMP15;
drop table VAR_MART_DB.TEMP15;
create index I_17 on VAR_MART_DB.TEMP16(name_2019);
rename table VAR_MART_DB.TEMP16 to VAR_MART_DB.SPECIES_ABBREV_snp__poly__dm;
create index I_18 on VAR_MART_DB.SPECIES_ABBREV_snp__poly__dm(variation_id_2025_key);
create table VAR_MART_DB.TEMP17 as select a.variation_id_2025_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_19 on VAR_MART_DB.TEMP17(variation_id_2025_key);
create table VAR_MART_DB.TEMP18 as select a.*,b.population_genotype_id as population_genotype_id_20107,b.allele_1 as allele_1_20107,b.population_id as population_id_20107,b.allele_2 as allele_2_20107,b.frequency as frequency_2016 from VAR_MART_DB.TEMP17 as a inner join VAR_DB.MTMP_population_genotype as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP17;
create index I_20 on VAR_MART_DB.TEMP18(population_id_20107);
create table VAR_MART_DB.TEMP19 as select a.*,b.name as name_2019,b.display_group_id as display_group_id_2015,b.size as size_2019 from VAR_MART_DB.TEMP18 as a inner join VAR_DB.population as b on a.population_id_20107=b.population_id;
drop table VAR_MART_DB.TEMP18;
create table VAR_MART_DB.TEMP21 as select name_2019,frequency_2016,display_group_id_2015,size_2019,allele_2_20107,population_id_20107,variation_id_2025_key,allele_1_20107,population_genotype_id_20107,concat(allele_1_20107, '|', allele_2_20107) as allele from VAR_MART_DB.TEMP19;
drop table VAR_MART_DB.TEMP19;
create index I_21 on VAR_MART_DB.TEMP21(variation_id_2025_key);
create table VAR_MART_DB.TEMP22 as select a.variation_id_2025_key,b.name_2019,b.allele_1_20107,b.population_id_20107,b.display_group_id_2015,b.allele,b.population_genotype_id_20107,b.size_2019,b.allele_2_20107,b.frequency_2016 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP21 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP21;
alter table VAR_MART_DB.TEMP22 drop column allele_1_20107;
alter table VAR_MART_DB.TEMP22 drop column population_id_20107;
alter table VAR_MART_DB.TEMP22 drop column display_group_id_2015;
alter table VAR_MART_DB.TEMP22 drop column population_genotype_id_20107;
alter table VAR_MART_DB.TEMP22 drop column allele_2_20107;
rename table VAR_MART_DB.TEMP22 to VAR_MART_DB.SPECIES_ABBREV_snp__population_genotype__dm;
create index I_22 on VAR_MART_DB.SPECIES_ABBREV_snp__population_genotype__dm(variation_id_2025_key);
create table VAR_MART_DB.TEMP23 as select a.variation_id_2025_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_23 on VAR_MART_DB.TEMP23(variation_id_2025_key);
create table VAR_MART_DB.TEMP24 as select a.*,b.variation_set_id as variation_set_id_2078 from VAR_MART_DB.TEMP23 as a inner join VAR_DB.MTMP_variation_set_variation as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP23;
create index I_24 on VAR_MART_DB.TEMP24(variation_set_id_2078);
create table VAR_MART_DB.TEMP25 as select a.*,b.description as description_2077,b.name as name_2077 from VAR_MART_DB.TEMP24 as a inner join VAR_DB.variation_set as b on a.variation_set_id_2078=b.variation_set_id;
drop table VAR_MART_DB.TEMP24;
create index I_25 on VAR_MART_DB.TEMP25(variation_id_2025_key);
create table VAR_MART_DB.TEMP26 as select a.variation_id_2025_key,b.variation_set_id_2078,b.description_2077,b.name_2077 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP25 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP25;
create index I_26 on VAR_MART_DB.TEMP26(name_2077);
rename table VAR_MART_DB.TEMP26 to VAR_MART_DB.SPECIES_ABBREV_snp__variation_set_variation__dm;
create index I_27 on VAR_MART_DB.SPECIES_ABBREV_snp__variation_set_variation__dm(variation_id_2025_key);
create table VAR_MART_DB.TEMP27 as select a.variation_id_2025_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_28 on VAR_MART_DB.TEMP27(variation_id_2025_key);
create table VAR_MART_DB.TEMP28 as select a.*,b.subsnp_id as subsnp_id_2010,b.allele_1 as allele_1_2010,b.allele_2 as allele_2_2010,b.individual_id as individual_id_2010 from VAR_MART_DB.TEMP27 as a left join VAR_DB.individual_genotype_multiple_bp as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP27;
create index I_29 on VAR_MART_DB.TEMP28(individual_id_2010);
create table VAR_MART_DB.TEMP30 as select a.*,b.individual_type_id as individual_type_id_2019,b.name as name_2019 from VAR_MART_DB.TEMP28 as a inner join VAR_DB.individual as b on a.individual_id_2010=b.individual_id and (b.display in ("REFERENCE","DEFAULT","DISPLAYABLE","MARTDISPLAYABLE"));
drop table VAR_MART_DB.TEMP28;
create index I_30 on VAR_MART_DB.TEMP30(individual_type_id_2019);
create table VAR_MART_DB.TEMP32 as select a.* from VAR_MART_DB.TEMP30 as a left join VAR_DB.individual_type as b on a.individual_type_id_2019=b.individual_type_id;
drop table VAR_MART_DB.TEMP30;
create table VAR_MART_DB.TEMP33 as select individual_type_id_2019,name_2019,individual_id_2010,allele_2_2010,variation_id_2025_key,subsnp_id_2010,allele_1_2010,concat(allele_1_2010, '|', allele_2_2010) as allele from VAR_MART_DB.TEMP32;
drop table VAR_MART_DB.TEMP32;
create index I_31 on VAR_MART_DB.TEMP33(variation_id_2025_key);
create table VAR_MART_DB.TEMP34 as select a.variation_id_2025_key,b.individual_id_2010,b.individual_type_id_2019,b.allele_2_2010,b.allele_1_2010,b.allele,b.subsnp_id_2010,b.name_2019 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP33 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP33;
create table VAR_MART_DB.TEMP35 as select distinct name_2019,individual_id_2010,allele,variation_id_2025_key from VAR_MART_DB.TEMP34;
drop table VAR_MART_DB.TEMP34;
create index I_32 on VAR_MART_DB.TEMP35(name_2019);
rename table VAR_MART_DB.TEMP35 to VAR_MART_DB.SPECIES_ABBREV_snp__mpoly__dm;
create index I_33 on VAR_MART_DB.SPECIES_ABBREV_snp__mpoly__dm(variation_id_2025_key);
create table VAR_MART_DB.TEMP36 as select a.variation_id_2025_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_34 on VAR_MART_DB.TEMP36(variation_id_2025_key);
create table VAR_MART_DB.TEMP37 as select a.*,b.risk_allele as associated_variant_risk_allele_2035,b.study_id as study_id_2035,b.associated_gene as associated_gene_2035,b.is_significant as is_significant_20133,b.variation_names as variation_names_2035,b.p_value as p_value_2035,b.phenotype_id as phenotype_id_2035 from VAR_MART_DB.TEMP36 as a inner join VAR_DB.MTMP_variation_annotation as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP36;
create index I_35 on VAR_MART_DB.TEMP37(phenotype_id_2035);
create table VAR_MART_DB.TEMP38 as select a.*,b.stable_id as stable_id_2033,b.description as description_2033 from VAR_MART_DB.TEMP37 as a inner join VAR_DB.phenotype as b on a.phenotype_id_2035=b.phenotype_id;
drop table VAR_MART_DB.TEMP37;
create index I_36 on VAR_MART_DB.TEMP38(study_id_2035);
create table VAR_MART_DB.TEMP39 as select a.*,b.external_reference as external_reference_20100,b.description as description_20100,b.source_id as source_id_20100,b.study_type as study_type_20100 from VAR_MART_DB.TEMP38 as a left join VAR_DB.study as b on a.study_id_2035=b.study_id;
drop table VAR_MART_DB.TEMP38;
create index I_37 on VAR_MART_DB.TEMP39(source_id_20100);
create table VAR_MART_DB.TEMP40 as select a.*,b.name as name_2021 from VAR_MART_DB.TEMP39 as a left join VAR_DB.source as b on a.source_id_20100=b.source_id;
drop table VAR_MART_DB.TEMP39;
create index I_38 on VAR_MART_DB.TEMP40(variation_id_2025_key);
create table VAR_MART_DB.TEMP41 as select a.variation_id_2025_key,b.associated_variant_risk_allele_2035,b.is_significant_20133,b.source_id_20100,b.stable_id_2033,b.associated_gene_2035,b.external_reference_20100,b.description_20100,b.phenotype_id_2035,b.study_type_20100,b.description_2033,b.name_2021,b.study_id_2035,b.p_value_2035,b.variation_names_2035 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP40 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP40;
alter table VAR_MART_DB.TEMP41 drop column phenotype_id_2035;
create index I_39 on VAR_MART_DB.TEMP41(study_type_20100);
create index I_40 on VAR_MART_DB.TEMP41(description_2033);
rename table VAR_MART_DB.TEMP41 to VAR_MART_DB.SPECIES_ABBREV_snp__variation_annotation__dm;
create index I_41 on VAR_MART_DB.SPECIES_ABBREV_snp__variation_annotation__dm(variation_id_2025_key);
alter table VAR_MART_DB.SPECIES_ABBREV_snp__variation__main add column (variation_annotation_bool integer default 0);
update VAR_MART_DB.SPECIES_ABBREV_snp__variation__main a set variation_annotation_bool=(select case count(1) when 0 then null else 1 end from VAR_MART_DB.SPECIES_ABBREV_snp__variation_annotation__dm b where a.variation_id_2025_key=b.variation_id_2025_key and not (b.associated_variant_risk_allele_2035 is null and b.is_significant_20133 is null and b.source_id_20100 is null and b.stable_id_2033 is null and b.associated_gene_2035 is null and b.external_reference_20100 is null and b.description_20100 is null and b.study_type_20100 is null and b.description_2033 is null and b.name_2021 is null and b.study_id_2035 is null and b.p_value_2035 is null and b.variation_names_2035 is null));
create index I_42 on VAR_MART_DB.SPECIES_ABBREV_snp__variation__main(variation_annotation_bool);
create table VAR_MART_DB.TEMP42 as select a.variation_id_2025_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_43 on VAR_MART_DB.TEMP42(variation_id_2025_key);
create table VAR_MART_DB.TEMP43 as select a.*,b.publication_id as publication_id_20139 from VAR_MART_DB.TEMP42 as a inner join VAR_DB.variation_citation as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP42;
create index I_44 on VAR_MART_DB.TEMP43(publication_id_20139);
create table VAR_MART_DB.TEMP44 as select a.*,b.pmcid as pmcid_20137,b.authors as authors_20137,b.title as title_20137,b.pmid as pmid_20137,b.year as year_20137,b.ucsc_id as ucsc_id_20137,b.doi as doi_20137 from VAR_MART_DB.TEMP43 as a inner join VAR_DB.publication as b on a.publication_id_20139=b.publication_id;
drop table VAR_MART_DB.TEMP43;
create index I_45 on VAR_MART_DB.TEMP44(variation_id_2025_key);
create table VAR_MART_DB.TEMP45 as select a.variation_id_2025_key,b.ucsc_id_20137,b.title_20137,b.pmcid_20137,b.doi_20137,b.publication_id_20139,b.authors_20137,b.year_20137,b.pmid_20137 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP44 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP44;
rename table VAR_MART_DB.TEMP45 to VAR_MART_DB.SPECIES_ABBREV_snp__variation_citation__dm;
create index I_46 on VAR_MART_DB.SPECIES_ABBREV_snp__variation_citation__dm(variation_id_2025_key);
alter table VAR_MART_DB.SPECIES_ABBREV_snp__variation__main add column (variation_citation_bool integer default 0);
update VAR_MART_DB.SPECIES_ABBREV_snp__variation__main a set variation_citation_bool=(select case count(1) when 0 then null else 1 end from VAR_MART_DB.SPECIES_ABBREV_snp__variation_citation__dm b where a.variation_id_2025_key=b.variation_id_2025_key and not (b.ucsc_id_20137 is null and b.title_20137 is null and b.pmcid_20137 is null and b.doi_20137 is null and b.publication_id_20139 is null and b.authors_20137 is null and b.year_20137 is null and b.pmid_20137 is null));
create index I_47 on VAR_MART_DB.SPECIES_ABBREV_snp__variation__main(variation_citation_bool);
create table VAR_MART_DB.TEMP46 as select a.variation_id_2025_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_48 on VAR_MART_DB.TEMP46(variation_id_2025_key);
create table VAR_MART_DB.TEMP47 as select a.*,b.sample_name as sample_name_2085 from VAR_MART_DB.TEMP46 as a inner join VAR_DB.strain_gtype_poly as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP46;
create index I_49 on VAR_MART_DB.TEMP47(variation_id_2025_key);
create table VAR_MART_DB.TEMP48 as select a.variation_id_2025_key,b.sample_name_2085 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a left join VAR_MART_DB.TEMP47 as b on a.variation_id_2025_key=b.variation_id_2025_key;
drop table VAR_MART_DB.TEMP47;
rename table VAR_MART_DB.TEMP48 to VAR_MART_DB.SPECIES_ABBREV_snp__strain_gtype_poly__dm;
create index I_50 on VAR_MART_DB.SPECIES_ABBREV_snp__strain_gtype_poly__dm(variation_id_2025_key);
create table VAR_MART_DB.TEMP49 as select a.description_2021,a.minor_allele_freq_2025,a.variation_citation_bool,a.minor_allele_2025,a.minor_allele_count_2025,a.name_2021,a.ancestral_allele_2025,a.clinical_significance_2025,a.variation_annotation_bool,a.variation_id_2025_key,a.name_2025,a.evidence_2025 from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main as a;
create index I_51 on VAR_MART_DB.TEMP49(variation_id_2025_key);
create table VAR_MART_DB.TEMP50 as select a.*,b.variation_feature_id as variation_feature_id_2026_key,b.seq_region_id as seq_region_id_2026,b.seq_region_start as seq_region_start_2026,b.variation_name as variation_name_2026,b.source_id as source_id_2026,b.map_weight as map_weight_2026,b.variation_set_id as variation_set_id_2026,b.seq_region_strand as seq_region_strand_2026,b.seq_region_end as seq_region_end_2026,b.allele_string as allele_string_2026 from VAR_MART_DB.TEMP49 as a left join VAR_DB.variation_feature as b on a.variation_id_2025_key=b.variation_id;
drop table VAR_MART_DB.TEMP49;
create index I_52 on VAR_MART_DB.TEMP50(source_id_2026);
create table VAR_MART_DB.TEMP51 as select a.* from VAR_MART_DB.TEMP50 as a left join VAR_DB.source as b on a.source_id_2026=b.source_id;
drop table VAR_MART_DB.TEMP50;
create index I_53 on VAR_MART_DB.TEMP51(seq_region_id_2026);
create table VAR_MART_DB.TEMP52 as select a.*,b.name as name_1059,b.coord_system_id as coord_system_id_1059 from VAR_MART_DB.TEMP51 as a left join CORE_DB.seq_region as b on a.seq_region_id_2026=b.seq_region_id;
drop table VAR_MART_DB.TEMP51;
create index I_54 on VAR_MART_DB.TEMP52(seq_region_id_2026);
create table VAR_MART_DB.TEMP54 as select a.*,b.coord_system_id as coord_system_id_2034 from VAR_MART_DB.TEMP52 as a left join VAR_DB.seq_region as b on a.seq_region_id_2026=b.seq_region_id;
drop table VAR_MART_DB.TEMP52;
create index I_55 on VAR_MART_DB.TEMP54(variation_set_id_2026);
create table VAR_MART_DB.TEMP55 as select a.* from VAR_MART_DB.TEMP54 as a left join VAR_DB.variation_set as b on a.variation_set_id_2026=b.variation_set_id;
drop table VAR_MART_DB.TEMP54;
alter table VAR_MART_DB.TEMP55 drop column coord_system_id_2034;
alter table VAR_MART_DB.TEMP55 drop column coord_system_id_1059;
alter table VAR_MART_DB.TEMP55 drop column source_id_2026;
create index I_56 on VAR_MART_DB.TEMP55(seq_region_start_2026);
create index I_57 on VAR_MART_DB.TEMP55(name_1059);
create index I_58 on VAR_MART_DB.TEMP55(name_2025);
rename table VAR_MART_DB.TEMP55 to VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main;
create index I_59 on VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main(variation_id_2025_key);
create index I_60 on VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main(variation_feature_id_2026_key);
alter table VAR_MART_DB.SPECIES_ABBREV_snp__variation__main add column (variation_feature_count integer default 0);
update VAR_MART_DB.SPECIES_ABBREV_snp__variation__main a set variation_feature_count=(select count(1) from VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main b where a.variation_id_2025_key=b.variation_id_2025_key and not (b.description_2021 is null and b.seq_region_start_2026 is null and b.clinical_significance_2025 is null and b.variation_feature_id_2026_key is null and b.variation_set_id_2026 is null and b.allele_string_2026 is null and b.minor_allele_2025 is null and b.name_1059 is null and b.ancestral_allele_2025 is null and b.evidence_2025 is null and b.minor_allele_freq_2025 is null and b.name_2021 is null and b.seq_region_id_2026 is null and b.name_2025 is null and b.seq_region_end_2026 is null and b.seq_region_strand_2026 is null and b.minor_allele_count_2025 is null and b.variation_name_2026 is null and b.map_weight_2026 is null));
create index I_61 on VAR_MART_DB.SPECIES_ABBREV_snp__variation__main(variation_feature_count);
alter table VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main add column (variation_feature_count integer default 0);
update VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main a set variation_feature_count=(select max(variation_feature_count) from VAR_MART_DB.SPECIES_ABBREV_snp__variation__main b where a.variation_id_2025_key=b.variation_id_2025_key);
create index I_62 on VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main(variation_feature_count);
create table VAR_MART_DB.TEMP56 as select a.variation_feature_id_2026_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main as a;
create index I_63 on VAR_MART_DB.TEMP56(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP57 as select a.*,b.feature_stable_id as feature_stable_id_20126,b.consequence_types as consequence_types_20126,b.allele_string as allele_string_20126 from VAR_MART_DB.TEMP56 as a inner join VAR_DB.MTMP_regulatory_feature_variation as b on a.variation_feature_id_2026_key=b.variation_feature_id;
drop table VAR_MART_DB.TEMP56;
create index I_64 on VAR_MART_DB.TEMP57(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP58 as select a.variation_feature_id_2026_key,b.feature_stable_id_20126,b.allele_string_20126,b.consequence_types_20126 from VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main as a left join VAR_MART_DB.TEMP57 as b on a.variation_feature_id_2026_key=b.variation_feature_id_2026_key;
drop table VAR_MART_DB.TEMP57;
create index I_65 on VAR_MART_DB.TEMP58(feature_stable_id_20126);
rename table VAR_MART_DB.TEMP58 to VAR_MART_DB.SPECIES_ABBREV_snp__regulatory_feature_variation__dm;
create index I_66 on VAR_MART_DB.SPECIES_ABBREV_snp__regulatory_feature_variation__dm(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP59 as select a.variation_feature_id_2026_key from VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main as a;
create index I_67 on VAR_MART_DB.TEMP59(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP60 as select a.*,b.feature_stable_id as feature_stable_id_20125,b.in_informative_position as in_informative_position_20125,b.motif_name as motif_name_20125,b.motif_score_delta as motif_score_delta_20125,b.consequence_types as consequence_types_20125,b.motif_start as motif_start_20125,b.allele_string as allele_string_20125 from VAR_MART_DB.TEMP59 as a inner join VAR_DB.MTMP_motif_feature_variation as b on a.variation_feature_id_2026_key=b.variation_feature_id;
drop table VAR_MART_DB.TEMP59;
create index I_68 on VAR_MART_DB.TEMP60(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP61 as select a.variation_feature_id_2026_key,b.allele_string_20125,b.motif_score_delta_20125,b.motif_name_20125,b.motif_start_20125,b.feature_stable_id_20125,b.consequence_types_20125,b.in_informative_position_20125 from VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main as a left join VAR_MART_DB.TEMP60 as b on a.variation_feature_id_2026_key=b.variation_feature_id_2026_key;
drop table VAR_MART_DB.TEMP60;
rename table VAR_MART_DB.TEMP61 to VAR_MART_DB.SPECIES_ABBREV_snp__motif_feature_variation__dm;
create index I_69 on VAR_MART_DB.SPECIES_ABBREV_snp__motif_feature_variation__dm(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP62 as select a.seq_region_id as seq_region_id_1020,a.stable_id as stable_id_1023,a.analysis_id as analysis_id_1020,a.gene_id as gene_id_1020 from CORE_DB.gene as a;
create index I_70 on VAR_MART_DB.TEMP62(gene_id_1020);
create table VAR_MART_DB.TEMP65 as select a.*,b.transcript_id as transcript_id_1064,b.seq_region_id as seq_region_id_1064,b.stable_id as stable_id_1066,b.analysis_id as analysis_id_1064,b.biotype as biotype_1064,b.seq_region_strand as seq_region_strand_1064 from VAR_MART_DB.TEMP62 as a inner join CORE_DB.transcript as b on a.gene_id_1020=b.gene_id;
drop table VAR_MART_DB.TEMP62;
create index I_71 on VAR_MART_DB.TEMP65(stable_id_1066);
create table VAR_MART_DB.TEMP68 as select a.*,b.polyphen_prediction as polyphen_prediction_2090,b.cds_end as cds_end_2090,b.pep_allele_string as pep_allele_string_2090,b.cdna_end as cdna_end_2090,b.cds_start as cds_start_2090,b.sift_prediction as sift_prediction_2090,b.cdna_start as cdna_start_2090,b.allele_string as allele_string_2090,b.sift_score as sift_score_2090,b.variation_feature_id as variation_feature_id_2026_key,b.distance_to_transcript as distance_to_transcript_2090,b.polyphen_score as polyphen_score_2090,b.consequence_types as consequence_types_2090,b.translation_end as translation_end_2090,b.translation_start as translation_start_2090 from VAR_MART_DB.TEMP65 as a inner join VAR_DB.MTMP_transcript_variation as b on a.stable_id_1066=b.feature_stable_id;
drop table VAR_MART_DB.TEMP65;
create index I_72 on VAR_MART_DB.TEMP68(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP69 as select a.* from VAR_MART_DB.TEMP68 as a inner join VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main as b on a.variation_feature_id_2026_key=b.variation_feature_id_2026_key;
drop table VAR_MART_DB.TEMP68;
create index I_73 on VAR_MART_DB.TEMP69(variation_feature_id_2026_key);
create table VAR_MART_DB.TEMP70 as select a.variation_feature_id_2026_key,b.allele_string_2090,b.stable_id_1023,b.cds_start_2090,b.cdna_end_2090,b.polyphen_prediction_2090,b.translation_end_2090,b.sift_score_2090,b.seq_region_id_1020,b.consequence_types_2090,b.seq_region_strand_1064,b.seq_region_id_1064,b.pep_allele_string_2090,b.analysis_id_1020,b.stable_id_1066,b.sift_prediction_2090,b.distance_to_transcript_2090,b.transcript_id_1064,b.gene_id_1020,b.cdna_start_2090,b.translation_start_2090,b.cds_end_2090,b.analysis_id_1064,b.polyphen_score_2090,b.biotype_1064 from VAR_MART_DB.SPECIES_ABBREV_snp__variation_feature__main as a left join VAR_MART_DB.TEMP69 as b on a.variation_feature_id_2026_key=b.variation_feature_id_2026_key;
drop table VAR_MART_DB.TEMP69;
alter table VAR_MART_DB.TEMP70 drop column seq_region_id_1020;
alter table VAR_MART_DB.TEMP70 drop column seq_region_id_1064;
alter table VAR_MART_DB.TEMP70 drop column analysis_id_1020;
alter table VAR_MART_DB.TEMP70 drop column transcript_id_1064;
alter table VAR_MART_DB.TEMP70 drop column analysis_id_1064;
create index I_74 on VAR_MART_DB.TEMP70(stable_id_1023);
create index I_75 on VAR_MART_DB.TEMP70(polyphen_prediction_2090);
create index I_76 on VAR_MART_DB.TEMP70(consequence_types_2090);
create index I_77 on VAR_MART_DB.TEMP70(stable_id_1066);
create index I_78 on VAR_MART_DB.TEMP70(sift_prediction_2090);
create index I_79 on VAR_MART_DB.TEMP70(cdna_start_2090);
create index I_80 on VAR_MART_DB.TEMP70(translation_start_2090);
rename table VAR_MART_DB.TEMP70 to VAR_MART_DB.SPECIES_ABBREV_snp__mart_transcript_variation__dm;
create index I_81 on VAR_MART_DB.SPECIES_ABBREV_snp__mart_transcript_variation__dm(variation_feature_id_2026_key);
