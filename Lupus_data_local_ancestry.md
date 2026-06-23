# Lupus GWAS Data Processing for Local Ancestry - June 2026

## Raw data

```bash
1713 GWAS_CLEANED_030111.fam
730060 GWAS_CLEANED_030111.bim
```

## Plink to vcf

```bash

## transform plink file to vcf
plink2 --bfile GWAS_CLEANED_030111 --snps-only 'just-acgt' --recode bgz vcf --out GWAS_CLEANED_030111

## get number of SNPs after filtering indels
bcftools stats Lupus_GWAS_final.vcf | grep "number of SNPs:"
## 729,916

```
## Phasing with SHAPEIT4

```bash
conda activate ~/miniforge3/envs/snakemake_env

```
