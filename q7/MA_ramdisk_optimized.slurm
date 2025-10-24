#!/bin/bash
#SBATCH --job-name=MA_ramdisk_optimized
#SBATCH --output=MA_ramdisk_%j.out
#SBATCH --error=MA_ramdisk_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mail-type=ALL
#SBATCH --nodes=1

# exit the script if it encounters an error or an undefined variable
set -euo pipefail

# === 环境设置 ===
# module purge >/dev/null 2>&1 || true
# module load gcc >/dev/null 2>&1 || true
# module load gnu-parallel

# get the number of CPU cores
CPUS=$SLURM_CPUS_PER_TASK

# build the program
echo "==> Building MA program..."
g++ -O3 -std=c++17 -o MA MA.cpp

# setup the ramdisk
RAMDISK_PATH="/dev/shm/MA_output_$$"
echo "==> Setting up RAMdisk at $RAMDISK_PATH"
mkdir -p "$RAMDISK_PATH"

# create the final output directory
mkdir -p out

# define the parameter combinations
computation_types=(forward backward centered)
boundary_handlings=(restricted cyclic padding)
n_values=(100 200 300 400 500)

echo "==> Starting MA parameter sweep with RAMdisk I/O optimization..."
echo "Using $CPUS CPU cores"
echo "RAMdisk path: $RAMDISK_PATH"
echo "Processing time: $(date)"

# generate all parameter combinations, output to RAMdisk
{
  for n in "${n_values[@]}"; do
    for comp_type in "${computation_types[@]}"; do
      for bound_handling in "${boundary_handlings[@]}"; do
        echo "$comp_type $bound_handling $n"
      done
    done
  done
} | parallel -j $CPUS --colsep ' ' '
  comp_type={1}
  bound_handling={2}
  n={3}
  comp_flag="--${comp_type}"
  bound_flag="--${bound_handling}"
  ramdisk_file="'$RAMDISK_PATH'/MA_${comp_type}_${bound_handling}_N${n}.txt"
  ramdisk_err="'$RAMDISK_PATH'/MA_${comp_type}_${bound_handling}_N${n}.err"
  echo "$(date "+%H:%M:%S") [START] Processing MA_${comp_type}_${bound_handling}_N${n} (RAMdisk)"
  ./MA "$comp_flag" "$bound_flag" "$n" > "$ramdisk_file" 2> "$ramdisk_err"
  if [ $? -eq 0 ]; then
    echo "$(date "+%H:%M:%S") [OK] Completed MA_${comp_type}_${bound_handling}_N${n} (RAMdisk)"
  else
    echo "$(date "+%H:%M:%S") [FAIL] Failed MA_${comp_type}_${bound_handling}_N${n} (RAMdisk)"
  fi
'

echo "==> All MA runs completed on RAMdisk. Recovering results..."

# copy all results from RAMdisk to final output directory
echo "==> Copying results from RAMdisk to out/ directory..."
cp "$RAMDISK_PATH"/*.txt out/ 2>/dev/null || echo "No .txt files found in RAMdisk"
cp "$RAMDISK_PATH"/*.err out/ 2>/dev/null || echo "No .err files found in RAMdisk"

# count the results
txt_count=$(ls out/*.txt 2>/dev/null | wc -l)
err_count=$(ls out/*.err 2>/dev/null | wc -l)

echo "==> Recovery completed!"
echo "Copied $txt_count output files and $err_count error files to out/ directory"

# cleanup RAMdisk
echo "==> Cleaning up RAMdisk..."
rm -rf "$RAMDISK_PATH"

echo "==> All done! Results are in the out/ directory"
