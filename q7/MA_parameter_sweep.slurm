#!/bin/bash
#SBATCH --job-name=MA_parameter_sweep
#SBATCH --output=MA_sweep_%j.out
#SBATCH --error=MA_sweep_%j.err
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

# 创建输出目录
mkdir -p out

# 定义参数组合
computation_types=(forward backward centered)
boundary_handlings=(restricted cyclic padding)
n_values=(1 2 3 4 5)

echo "==> Starting MA parameter sweep..."
echo "Using $CPUS CPU cores"
echo "Processing time: $(date)"

# 生成所有参数组合 (N从1到5，每种computation_type和boundary_handling的组合)
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
  ofile="out/MA_${comp_type}_${bound_handling}_N${n}.txt"
  efile="out/MA_${comp_type}_${bound_handling}_N${n}.err"
  echo "$(date "+%H:%M:%S") [START] Processing MA_${comp_type}_${bound_handling}_N${n}"
  ./MA "$comp_flag" "$bound_flag" "$n" > "$ofile" 2> "$efile"
  if [ $? -eq 0 ]; then
    echo "$(date "+%H:%M:%S") [OK] Completed MA_${comp_type}_${bound_handling}_N${n}"
  else
    echo "$(date "+%H:%M:%S") [FAIL] Failed MA_${comp_type}_${bound_handling}_N${n}"
  fi
'

echo "==> All MA parameter sweep runs completed. Outputs in q7/out/."

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

echo "Parameter sweep completed successfully!"
