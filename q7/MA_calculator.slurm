#!/bin/bash
#SBATCH --job-name=MA_calculator
#SBATCH --output=MA_job_%j.out
#SBATCH --error=MA_job_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mail-type=ALL
#SBATCH --nodes=1



# 获取CPU核心数
CPUS=$SLURM_CPUS_PER_TASK

# 构建程序
echo "==> Building MA program..."
g++ -O3 -std=c++17 -o MA MA.cpp

# 创建输出目录
mkdir -p out

# 定义参数组合
types=(forward backward centered)
bounds=(restricted cyclic padding)
n_values=(100 200 300 400 500)

echo "==> Starting MA calculations..."
echo "Using $CPUS CPU cores"
echo "Processing time: $(date)"

# 生成所有参数组合
{
  for n in "${n_values[@]}"; do
    for t in "${types[@]}"; do
      for b in "${bounds[@]}"; do
        echo "$t $b $n"
      done
    done
  done
} | parallel -j $CPUS --colsep ' ' '
  t={1}
  b={2}
  n={3}
  t_flag="--${t}"
  b_flag="--${b}"
  ofile="out/MA_${t}_${b}_N${n}.txt"
  efile="out/MA_${t}_${b}_N${n}.err"
  echo "$(date "+%H:%M:%S") [START] Processing MA_${t}_${b}_N${n}"
  ./MA "$t_flag" "$b_flag" "$n" > "$ofile" 2> "$efile"
  if [ $? -eq 0 ]; then
    echo "$(date "+%H:%M:%S") [OK] Completed MA_${t}_${b}_N${n}"
  else
    echo "$(date "+%H:%M:%S") [FAIL] Failed MA_${t}_${b}_N${n}"
  fi
'

