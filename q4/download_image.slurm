#!/bin/bash
#SBATCH --job-name=download_blue_marble
#SBATCH --output=download_blue_marble_%j.out
#SBATCH --error=download_blue_marble_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mail-type=ALL
#SBATCH --nodes=1


# module load intel/2018.2 gsl/2.4
# module load gnu-parallel
mkdir -p logs images

CPUS=$SLURM_CPUS_PER_TASK

BASE_URL = "https://www.example.com/path/to/YYYYMMDD ##.jpg"
DATES=()
for i in $(seq 0 29); do
    DATES+=("$(date -d "-$i day" +%Y%m%d)")
done

# 生成所有下载 URL
URLS_FILE="urls.txt"
> "$URLS_FILE"

for d in "${DATES[@]}"; do
    for n in $(seq -w 1 24); do
        echo "${BASE_URL}/${d}_${n}.jpg" >> "$URLS_FILE"
    done
done

echo "Generated $(wc -l < $URLS_FILE) URLs."

# 使用 GNU Parallel 并行下载
module load parallel 2>/dev/null || true
module load wget 2>/dev/null || true

cat "$URLS_FILE" | parallel -j $SLURM_CPUS_PER_TASK "wget -q -c -P images {}"

echo "All downloads completed at $(date)"