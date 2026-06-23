# Lupus GWAS Data Processing for Local Ancestry - June 2026

## Raw data

```bash
1713 GWAS_CLEANED_030111.fam
730060 GWAS_CLEANED_030111.bim
```

## Plink to vcf

```bash

module load plink
module load bcftools

## transform plink file to vcf
plink2 --bfile GWAS_CLEANED_030111 --snps-only 'just-acgt' --recode bgz vcf --out GWAS_CLEANED_030111

## create index
bcftools index -c /mnt/home_users/cdquinto/Lupus_GWAS/GWAS_CLEANED_030111.vcf.gz

## get number of SNPs after filtering indels
bcftools stats Lupus_GWAS_final.vcf | grep "number of SNPs:"
## 729,916

```
## Phasing with SHAPEIT4

```bash

salloc -p heavy -c 8 --mem=40G

conda activate /mnt/home_users/cdquinto/miniforge3/envs/snakemake_env



```
