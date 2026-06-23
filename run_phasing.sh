#!/bin/bash
#SBATCH --job-name=lupus_phasing
#SBATCH --partition=heavy
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --time=12:00:00
#SBATCH --output=phasing_master_%j.log
#SBATCH --error=phasing_master_%j.err

# 1. Cargar el entorno de Conda de forma estricta para scripts no interactivos
source /mnt/home_users/cdquinto/miniforge3/etc/profile.d/conda.sh
conda activate /mnt/home_users/cdquinto/miniforge3/envs/snakemake_env

# 2. Ejecutar Snakemake de forma local DENTRO del nodo de cálculo asignado
# Usamos --cores 8 porque le asignamos 8 cpus en los encabezados de arriba
snakemake -s /mnt/home_users/cdquinto/Lupus_GWAS/snakefile-shapeit4.smk --cores 8
