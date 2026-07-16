#!/bin/bash

# Define directories for easy modification
WORKING_DIR="/mnt/home_users/cdquinto/Lupus_GWAS/local_ancestry/"
MAP_DIR="/mnt/home_users/cdquinto/references/genetic_map_b37_gnomix"

# Change to working directory
cd "$WORKING_DIR"

# Loop through chromosomes 1 to 22
for chr in {1..22}
do
    echo "Generating and submitting Slurm script for Chromosome $chr..."

    # Use a 'here-document' (cat << 'EOF') to build the Slurm script on the fly
    sbatch << EOF
#!/bin/bash
#SBATCH --job-name=gnomix_chr${chr}
#SBATCH --partition=light
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --time=100:00:00
#SBATCH --output=gnomix_chr${chr}_%j.log
#SBATCH --error=gnomix_chr${chr}_%j.err

cd $WORKING_DIR

module load gnomix

# Run Gnomix for the current chromosome
# Note: If your cluster requires "gnomix.py", adjust the command below accordingly.
gnomix query_chr${chr}.vcf.gz chr${chr} ${chr} True ${MAP_DIR}/chr${chr}_fixed.gmap.gz references_chr${chr}.vcf.gz references.smap

EOF

done

echo "All 22 jobs have been submitted to the Slurm queue."

