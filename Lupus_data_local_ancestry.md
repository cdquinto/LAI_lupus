# Lupus GWAS Data Processing for Local Ancestry - June 2026

## Raw data IN hg18!!!!

### Download references for liftOver

```bash
# Download the primary assembly from Ensembl (Uses 1, 2, X without "chr")
wget ftp://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz

# Decompress it
gunzip Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz

# Download fasta file
wget https://hgdownload.cse.ucsc.edu/goldenPath/hg18/liftOver/hg18ToHg19.over.chain.gz
```

### Run liftOver hg18 to hg19

```bash
module load bcftools

bcftools plugin liftover \
  GWAS_CLEANED_030111.vcf.gz \
  -o GWAS.hg19.vcf.gz \
  -- \
  -c /mnt/home_users/cdquinto/references/hg18ToHg19.over.chain.gz \
  -f /mnt/home_users/cdquinto/references/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa

```

### Plink to vcf (remove indels)

```bash

module load plink
module load bcftools

## transform plink file to vcf
plink2 --vcf GWAS.hg19.vcf.gz --snps-only 'just-acgt' --chr 1-22 --recode bgz vcf --out GWAS.hg19.cleaned

## 712849 variants remaining after main filters.

## sort the liftover output and save it as a new, compressed VCF
bcftools sort GWAS.hg19.cleaned.vcf.gz -O z -o GWAS.hg19.sorted.vcf.gz

## index the sorted file
bcftools index -c GWAS.hg19.sorted.vcf.gz

## get number of SNPs after filtering indels
bcftools stats GWAS.hg19.sorted.vcf.gz | grep "number of SNPs:"
## 712849

```
### Phasing with SHAPEIT4

```bash

sbatch run_phasing.sh

```
## Build reference panel to train gnomix panel
/data/data_lab/reference_panels/1KGP_plink/
