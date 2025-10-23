#!/bin/bash
#SBATCH --job-name=hmm_search_monitored
#SBATCH --output=hmm_search_%j.out
#SBATCH --error=hmm_search_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --partition=compute
#SBATCH --mail-type=ALL
#SBATCH --nodes=1

# 让脚本在出错或未定义变量时立即退出
set -euo pipefail

# === 环境设置 ===
# parallel 命令已安装在系统中，无需加载模块
module load hmmer

# 工作目录
WORKDIR=/home/l/lcl_uotcscd71/lcl_uotcscd71s1408/hmmer-3.4
cd $WORKDIR

# Pfam 模型路径
PFAM=$WORKDIR/Pfam-A.hmm

# 如果还没建立索引，就建一下
if [ ! -f "$PFAM.h3f" ]; then
  echo "==> Building HMM index..."
  hmmpress $PFAM
fi

# 输出目录
OUTDIR=$WORKDIR/hmm_out
mkdir -p $OUTDIR

# 监控输出目录
MONITOR_DIR=$WORKDIR/monitoring_output
mkdir -p $MONITOR_DIR

# 并行参数设置（根据 Slurm 分配的 CPU 自动计算并行度）
TOTAL_CPUS=${SLURM_CPUS_PER_TASK:-40}
THREADS=4                                  # 每个 hmmscan 使用的 CPU 数
PARALLEL_JOBS=$(( TOTAL_CPUS / THREADS ))  # 同时运行的 hmmscan 任务数
if [ "$PARALLEL_JOBS" -lt 1 ]; then PARALLEL_JOBS=1; fi

echo "==== Job Configuration ===="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Total CPUs allocated: $TOTAL_CPUS"
echo "Threads per hmmscan: $THREADS"
echo "Parallel jobs: $PARALLEL_JOBS"
echo "Start time: $(date)"
echo

# === 启动后台监控进程 ===
echo "==== Starting Resource Monitoring ===="

# 启动 jobperf 监控（每30秒采样一次）
jobperf -j $SLURM_JOB_ID -i 30 > $MONITOR_DIR/jobperf_output.txt 2>&1 &
JOBPERF_PID=$!

# 启动系统资源监控（每10秒采样一次）
{
  echo "timestamp,cpu_usage,memory_usage,load_avg" > $MONITOR_DIR/system_stats.csv
  while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    memory_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "$timestamp,$cpu_usage,$memory_usage,$load_avg" >> $MONITOR_DIR/system_stats.csv
    sleep 10
  done
} &
SYSTEM_MONITOR_PID=$!

# 启动 I/O 监控
iostat -x 10 > $MONITOR_DIR/iostat_output.txt 2>&1 &
IOSTAT_PID=$!

echo "Monitoring processes started:"
echo "  jobperf PID: $JOBPERF_PID"
echo "  system monitor PID: $SYSTEM_MONITOR_PID"
echo "  iostat PID: $IOSTAT_PID"
echo

# === 执行 HMMER 搜索 ===
echo "==== Starting HMMER Search ===="
START_TIME=$(date +%s)

# 跳过 uniprot_sprot.fasta 文件
find $WORKDIR -maxdepth 1 -name "uniprot_*.fasta" ! -name "uniprot_sprot.fasta" | \
parallel --will-cite -j $PARALLEL_JOBS hmmscan --cpu $THREADS --noali \
  --domtblout $OUTDIR/{/.}.domtblout \
  $PFAM {} '>' $OUTDIR/{/.}.out

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

echo "==> All hmmsearch jobs completed."
echo "Execution time: ${EXECUTION_TIME} seconds"

# === 停止监控进程 ===
echo
echo "==== Stopping Monitoring Processes ===="
kill $JOBPERF_PID 2>/dev/null || true
kill $SYSTEM_MONITOR_PID 2>/dev/null || true
kill $IOSTAT_PID 2>/dev/null || true

# 等待进程完全停止
sleep 2

# === 生成监控报告 ===
echo
echo "==== Resource Utilization Analysis ===="

# SLURM 作业统计
echo "--- SLURM Job Statistics ---"
sacct -j $SLURM_JOB_ID --format=JobID,State,Elapsed,TotalCPU,MaxRSS,ReqCPUS,MaxVMSize,MaxDiskRead,MaxDiskWrite

echo
echo "--- Jobperf Analysis ---"
if [ -f "$MONITOR_DIR/jobperf_output.txt" ]; then
  echo "Jobperf monitoring completed. Check $MONITOR_DIR/jobperf_output.txt for details."
  # 显示最后几行 jobperf 输出
  echo "Last jobperf entries:"
  tail -5 "$MONITOR_DIR/jobperf_output.txt" 2>/dev/null || echo "No jobperf data available"
else
  echo "Jobperf monitoring data not available"
fi

echo
echo "--- Real-time System Statistics ---"
if [ -f "$MONITOR_DIR/system_stats.csv" ]; then
  echo "System monitoring completed. Check $MONITOR_DIR/system_stats.csv for details."
  echo "Peak CPU usage: $(awk -F',' 'NR>1 {if($2>max) max=$2} END {print max "%"}' $MONITOR_DIR/system_stats.csv)"
  echo "Peak Memory usage: $(awk -F',' 'NR>1 {if($3>max) max=$3} END {printf "%.2f%%\n", max}' $MONITOR_DIR/system_stats.csv)"
  echo "Peak Load average: $(awk -F',' 'NR>1 {if($4>max) max=$4} END {print max}' $MONITOR_DIR/system_stats.csv)"
else
  echo "System monitoring data not available"
fi

echo
echo "--- I/O Statistics ---"
if [ -f "$MONITOR_DIR/iostat_output.txt" ]; then
  echo "I/O monitoring completed. Check $MONITOR_DIR/iostat_output.txt for details."
  echo "Average I/O wait: $(grep -v "^$" $MONITOR_DIR/iostat_output.txt | grep -v "Device" | awk '{sum+=$10; count++} END {if(count>0) printf "%.2f%%\n", sum/count; else print "N/A"}')"
else
  echo "I/O monitoring data not available"
fi

echo
echo "==== Comparison Analysis ===="
echo "Comparing jobperf (SLURM-level) vs real-time monitoring (system-level):"
echo
echo "1. SLURM jobperf provides:"
echo "   - Job-level resource accounting"
echo "   - Historical resource usage"
echo "   - Peak and average resource consumption"
echo "   - Integration with SLURM scheduler"
echo
echo "2. Real-time monitoring provides:"
echo "   - Instantaneous system state"
echo "   - Detailed I/O statistics"
echo "   - System load and CPU utilization"
echo "   - Memory usage patterns"
echo
echo "3. Key differences:"
echo "   - jobperf shows SLURM-accounted resources (may differ from actual system usage)"
echo "   - Real-time monitoring shows actual system resource consumption"
echo "   - jobperf is more accurate for billing and job accounting"
echo "   - Real-time monitoring is better for performance tuning"
echo
echo "4. Conclusions:"
echo "   - Use jobperf for job accounting and resource limits"
echo "   - Use real-time monitoring for performance optimization"
echo "   - Both are needed for comprehensive resource analysis"
echo "   - Discrepancies may indicate resource contention or inefficiencies"

echo
echo "==== Monitoring Data Location ===="
echo "All monitoring data saved to: $MONITOR_DIR/"
echo "  - jobperf_output.txt: SLURM job performance data"
echo "  - system_stats.csv: Real-time system statistics"
echo "  - iostat_output.txt: I/O performance data"
echo
echo "Job completed at: $(date)"
