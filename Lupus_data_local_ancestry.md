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
Reference data path: `/data/data_lab/reference_panels/1KGP_plink/`

```bash
bcftools query -f '%ID\n' /mnt/home_users/cdquinto/Lupus_GWAS/phasing/GWAS.hg19.sorted.phased.autosomes.vcf.gz > /mnt/home_users/cdquinto/Lupus_GWAS/local_ancestry/GWAS_phased_snp_ids.txt

cut -f2 /data/data_lab/reference_panels/1KGP_plink/ALL.atDNA.biAllelicSNPnoDI.genotypes.id.bim | sort -u > /mnt/home_users/cdquinto/Lupus_GWAS/local_ancestry/1KGP_snp_ids.txt

awk 'NR==FNR {a[$1]; next} $1 in a' 1KGP_snp_ids.txt GWAS_phased_snp_ids.txt > common_snps.txt

## 345244 common_snps.txt
````
### Extract samples

```bash
# Define populations and target counts
declare -A targets=( [IBS]=10 [TSI]=10 [CEU]=10 [YRI]=10 [ESN]=10 [GWD]=10 [MSL]=10 )

# Clear output file if it exists
> sample_ids.txt

# Loop through each pop, filter the metadata, shuffle, and extract the exact count
for pop in "${!targets[@]}"; do
    count=${targets[$pop]}
    awk -v p="$pop" '$6 == p {print $6 "\t" $2}' /data/data_lab/reference_panels/1KGP_plink/1KGP3.popinfo.txt | shuf -n "$count" >> sample_ids.txt
done

echo "Extracted $(wc -l < sample_ids.txt) sample IDs to sample_ids.txt"

## added the NAT samples from 1KG
````

### Extract sites and selected samples from 1KG reference

```bash
plink2 --bfile /data/data_lab/reference_panels/1KGP_plink/ALL.atDNA.biAllelicSNPnoDI.genotypes.id --keep sample_ids.txt --extract common_snps.txt --recode bgz vcf --make-bed --out references_1KG
```

### Extract sites from GWAS Lupus data

```bash
plink2 --vcf /mnt/home_users/cdquinto/Lupus_GWAS/phasing/GWAS.hg19.sorted.phased.autosomes.vcf.gz --extract /mnt/home_users/cdquinto/Lupus_GWAS/local_ancestry/common_snps.txt --recode bgz vcf --out GWAS.hg19.common
```

### Merge datasets

```bash
bcftools index -c references_1KG.vcf.gz
bcftools index -c GWAS.hg19.common.vcf.gz

# 1. Normalize and check alleles against the hg19 reference FASTA
bcftools norm -f /mnt/home_users/cdquinto/references/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa -m +any GWAS.hg19.common.vcf.gz -O z -o GWAS.hg19.normalized.vcf.gz

bcftools index -c GWAS.hg19.normalized.vcf.gz

# 2. Try merging again with the normalized file
bcftools merge -m none references_1KG.vcf.gz GWAS.hg19.common.vcf.gz -o merged_for_gnomix.vcf.gz -O z

bcftools index -c merged_for_gnomix.vcf.gz

bcftools query -l merged_for_gnomix.vcf.gz > samples_list_gnomix.txt
```

### Split again into references and query

```bash
module load plink

for i in {1..22}
do
plink2 --vcf merged_for_gnomix.vcf.gz --keep references_ids.txt --chr ${i} --recode bgz vcf --out references_chr${i}
plink2 --vcf merged_for_gnomix.vcf.gz --keep query_ids.txt --chr ${i} --recode bgz vcf --out query_chr${i}
done
```

### Reformat genetic maps

```bash
for i in {1..22}
do
zcat /data/data_vault/rgonzalez/resources/genetic_maps/shapeit4_GM/b37/chr${i}.b37.gmap.gz | awk 'BEGIN{OFS="\t"} NR>1 {print $2, $1, $3}' | gzip > /mnt/home_users/cdquinto/references/genetic_map_b37_gnomix/chr${i}_fixed.gmap.gz
done
```

### Generate slurm batch file and submit jobs

```bash
./run_gnomix_all.sh
```

