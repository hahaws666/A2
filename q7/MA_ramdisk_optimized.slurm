#!/bin/bash
#SBATCH --job-name=MA_ramdisk_optimized
#SBATCH --output=MA_ramdisk_%j.out
#SBATCH --error=MA_ramdisk_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mail-type=ALL
#SBATCH --nodes=1

# 让脚本在出错或未定义变量时立即退出
set -euo pipefail

# === 环境设置 ===
module purge >/dev/null 2>&1 || true
module load gcc >/dev/null 2>&1 || true
module load gnu-parallel

# 获取CPU核心数
CPUS=$SLURM_CPUS_PER_TASK

# 构建程序
echo "==> Building MA program..."
g++ -O3 -std=c++17 -o MA MA.cpp

# === RAMdisk 设置 ===
RAMDISK_PATH="/dev/shm/MA_output_$$"
echo "==> Setting up RAMdisk at $RAMDISK_PATH"
mkdir -p "$RAMDISK_PATH"

# 创建最终输出目录
mkdir -p out

# 定义参数组合
computation_types=(forward backward centered)
boundary_handlings=(restricted cyclic padding)
n_values=(1 2 3 4 5)

echo "==> Starting MA parameter sweep with RAMdisk I/O optimization..."
echo "Using $CPUS CPU cores"
echo "RAMdisk path: $RAMDISK_PATH"
echo "Processing time: $(date)"

# 生成所有参数组合，输出到RAMdisk
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

# === 数据恢复：从RAMdisk复制到最终输出目录 ===
echo "==> Recovering results from RAMdisk to final output directory..."
cp "$RAMDISK_PATH"/*.txt out/ 2>/dev/null || true
cp "$RAMDISK_PATH"/*.err out/ 2>/dev/null || true

# 清理RAMdisk
echo "==> Cleaning up RAMdisk..."
rm -rf "$RAMDISK_PATH"

echo "==> All MA runs completed. Outputs recovered to q7/out/."

# === 性能报告 ===
echo
echo "==== Job performance summary ===="
sacct -j $SLURM_JOB_ID --format=JobID,State,Elapsed,TotalCPU,MaxRSS,ReqCPUS

# === 结果统计 ===
echo
echo "==== Results summary ===="
total_runs=$(find out -name "MA_*.txt" | wc -l)
successful_runs=$(find out -name "MA_*.txt" -size +0c | wc -l)
failed_runs=$((total_runs - successful_runs))

echo "Total runs: $total_runs"
echo "Successful runs: $successful_runs"
echo "Failed runs: $failed_runs"

if [ $failed_runs -gt 0 ]; then
  echo "Failed runs details:"
  find out -name "MA_*.txt" -size 0c | while read file; do
    echo "  $(basename "$file")"
  done
fi

echo "RAMdisk-optimized parameter sweep completed successfully!"
