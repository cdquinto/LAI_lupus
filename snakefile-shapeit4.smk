# ============================================================
# Phasing Lupus GWAS VCF with SHAPEIT4 (NOMAF branch only)
# ============================================================

import os

# ============================================================
# Global settings
# ============================================================

CHRS = list(range(1, 23))

BCFTOOLS = "bcftools"
SHAPEIT4 = "shapeit4"

# Rutas de entrada actualizadas
GENETIC_MAP_DIR = "/data/data_vault/rgonzalez/resources/genetic_maps/shapeit4_GM/b37"
LUPUS_INPUT_VCF = "/mnt/home_users/cdquinto/Lupus_GWAS/GWAS_CLEANED_030111.vcf.gz"

# Nueva ruta base para tus resultados personalizados
OUT_DIR = "/mnt/home_users/cdquinto/Lupus_GWAS"
RESULTS = "phasing" # Se mantiene para archivos temporales/logs si lo deseas

# ============================================================
# Final targets
# ============================================================

rule all:
    input:
        expand(f"{OUT_DIR}/GWAS_CLEANED_030111.phased.chr{{chr}}.vcf.gz.csi", chr=CHRS),
        f"{OUT_DIR}/GWAS_CLEANED_030111.phased.autosomes.vcf.gz.csi"


# ============================================================
# NOMAF SECTION
# ============================================================

rule split_nomaf_by_chr:
    input:
        vcf = LUPUS_INPUT_VCF
    output:
        vcf_gz = f"{RESULTS}/split/GWAS_CLEANED_030111.chr{{chr}}.vcf.gz",
        csi    = f"{RESULTS}/split/GWAS_CLEANED_030111.chr{{chr}}.vcf.gz.csi"
    threads: 4
    log:
        f"{RESULTS}/logs/split.chr{{chr}}.log"
    resources:
        mem_mb = 12000,
        runtime = 120,
        slurm_partition = "heavy"
    shell:
        r"""
        set -euo pipefail

        module load bcftools

        mkdir -p $(dirname {output.vcf_gz}) $(dirname {log})

        {BCFTOOLS} view \
          --threads {threads} \
          -r {wildcards.chr} \
          -Oz \
          -o {output.vcf_gz} \
          {input.vcf} \
          > {log} 2>&1

        {BCFTOOLS} index \
          --threads {threads} \
          -c \
          {output.vcf_gz} \
          >> {log} 2>&1
        """


rule phase_nomaf_chr:
    input:
        vcf_gz = f"{RESULTS}/split/GWAS_CLEANED_030111.chr{{chr}}.vcf.gz",
        csi    = f"{RESULTS}/split/GWAS_CLEANED_030111.chr{{chr}}.vcf.gz.csi"
    output:
        # Redirigido a tu ruta personalizada y con tu patrón de nombres exacto
        vcf_gz = f"{OUT_DIR}/GWAS_CLEANED_030111.phased.chr{{chr}}.vcf.gz"
    params:
        genetic_map = GENETIC_MAP_DIR + "/chr{chr}.b37.gmap.gz",
        region = "{chr}",
        shapeit_log = f"{RESULTS}/logs/GWAS_CLEANED_030111.phased.chr{{chr}}.shapeit4.log"
    threads: 8
    log:
        f"{RESULTS}/logs/phase.chr{{chr}}.log"
    resources:
        mem_mb = 40000,
        runtime = 720,
        slurm_partition = "heavy"
    shell:
        r"""
        set -euo pipefail
        
        module load shapeit4
        module load bcftools

        mkdir -p $(dirname {output.vcf_gz}) $(dirname {log})

        {SHAPEIT4} \
          --input {input.vcf_gz} \
          --map {params.genetic_map} \
          --region {params.region} \
          --log {params.shapeit_log} \
          --seed 123456 \
          --thread {threads} \
          --output {output.vcf_gz} \
          > {log} 2>&1
        """


rule index_nomaf_phased_chr:
    input:
        vcf_gz = f"{OUT_DIR}/GWAS_CLEANED_030111.phased.chr{{chr}}.vcf.gz"
    output:
        csi = f"{OUT_DIR}/GWAS_CLEANED_030111.phased.chr{{chr}}.vcf.gz.csi"
    threads: 4
    log:
        f"{RESULTS}/logs/index_phased.chr{{chr}}.log"
    resources:
        mem_mb = 8000,
        runtime = 60,
        slurm_partition = "heavy"
    shell:
        r"""
        set -euo pipefail

        module load bcftools

        {BCFTOOLS} index \
          --threads {threads} \
          -c \
          {input.vcf_gz} \
          > {log} 2>&1
        """


rule concat_nomaf_phased_autosomes:
    input:
        vcfs = expand(f"{OUT_DIR}/GWAS_CLEANED_030111.phased.chr{{chr}}.vcf.gz", chr=CHRS),
        csis = expand(f"{OUT_DIR}/GWAS_CLEANED_030111.phased.chr{{chr}}.vcf.gz.csi", chr=CHRS)
    output:
        vcf_gz = f"{OUT_DIR}/GWAS_CLEANED_030111.phased.autosomes.vcf.gz",
        csi    = f"{OUT_DIR}/GWAS_CLEANED_030111.phased.autosomes.vcf.gz.csi"
    threads: 4
    log:
        f"{RESULTS}/logs/concat_phased_autosomes.log"
    resources:
        mem_mb = 20000,
        runtime = 180,
        slurm_partition = "heavy"
    shell:
        r"""
        set -euo pipefail

        module load bcftools

        {BCFTOOLS} concat \
          --threads {threads} \
          -Oz \
          -o {output.vcf_gz} \
          {input.vcfs} \
          > {log} 2>&1

        {BCFTOOLS} index \
          --threads {threads} \
          -c \
          {output.vcf_gz} \
          >> {log} 2>&1
        """
