# HMMER 并行搜索与资源监控脚本

## 概述

这是一个增强版的SLURM批处理脚本，用于执行HMMER并行搜索并监控资源利用率。该脚本不仅执行HMMER搜索任务，还集成了多种资源监控工具，包括SLURM的jobperf和实时系统监控，以满足作业性能分析的需求。

## 主要功能

### 1. HMMER 并行搜索
- 自动检测并构建Pfam HMM索引
- 使用GNU parallel实现多文件并行处理
- 智能CPU资源分配（40个CPU核心，每个hmmscan使用4个线程）
- 跳过大型的uniprot_sprot.fasta文件，处理其他uniprot_*.fasta文件

### 2. 资源监控系统
- **SLURM jobperf监控**: 每30秒采样一次，记录作业级别的资源使用情况
- **实时系统监控**: 每10秒采样一次，记录CPU使用率、内存使用率和系统负载
- **I/O性能监控**: 使用iostat监控磁盘I/O性能

### 3. 数据分析与比较
- 自动生成资源利用率分析报告
- 对比SLURM jobperf与实时监控的差异
- 提供性能优化建议

## 文件结构

```
q9/
├── hmm_search.slurm          # 主SLURM脚本
├── README.md                 # 本说明文件
├── answer.md                 # 作业答案
└── monitoring_output/        # 监控数据输出目录（运行时创建）
    ├── jobperf_output.txt    # SLURM jobperf监控数据
    ├── system_stats.csv      # 实时系统统计数据
    └── iostat_output.txt     # I/O性能数据
```

## 使用方法

### 1. 提交作业
```bash
sbatch hmm_search.slurm
```

### 2. 查看作业状态
```bash
squeue -u $USER
```

### 3. 实时监控作业
```bash
# 查看作业输出
tail -f hmm_search_<job_id>.out

# 查看作业错误日志
tail -f hmm_search_<job_id>.err
```

### 4. 查看监控数据
作业完成后，检查监控数据：
```bash
# 查看SLURM作业统计
sacct -j <job_id> --format=JobID,State,Elapsed,TotalCPU,MaxRSS,ReqCPUS

# 查看监控数据目录
ls -la monitoring_output/

# 查看实时系统统计
cat monitoring_output/system_stats.csv

# 查看jobperf数据
cat monitoring_output/jobperf_output.txt
```

## 脚本配置参数

### SLURM参数
- **作业名称**: hmm_search_monitored
- **运行时间**: 1小时
- **CPU核心数**: 40个
- **分区**: compute
- **邮件通知**: 全部状态

### 并行处理参数
- **总CPU数**: 40个（由SLURM分配）
- **每个hmmscan线程数**: 4个
- **并行作业数**: 10个（40÷4=10）

### 监控参数
- **jobperf采样间隔**: 30秒
- **系统监控采样间隔**: 10秒
- **I/O监控采样间隔**: 10秒

## 监控数据说明

### 1. jobperf_output.txt
包含SLURM作业级别的资源使用统计：
- CPU时间使用情况
- 内存使用峰值
- 作业运行时间
- 资源利用率

### 2. system_stats.csv
包含实时系统统计数据（CSV格式）：
- timestamp: 时间戳
- cpu_usage: CPU使用率（%）
- memory_usage: 内存使用率（%）
- load_avg: 系统负载平均值

### 3. iostat_output.txt
包含磁盘I/O性能数据：
- 磁盘读写速度
- I/O等待时间
- 磁盘利用率

## 性能分析

### SLURM jobperf vs 实时监控对比

| 监控类型 | 优势 | 用途 |
|---------|------|------|
| **SLURM jobperf** | • 作业级别资源统计<br>• 历史资源使用记录<br>• 与调度器集成<br>• 计费准确性 | • 作业资源核算<br>• 资源限制管理<br>• 作业历史分析 |
| **实时系统监控** | • 瞬时系统状态<br>• 详细I/O统计<br>• 系统负载监控<br>• 内存使用模式 | • 性能调优<br>• 系统瓶颈识别<br>• 实时问题诊断 |

### 关键差异
1. **资源统计范围**: jobperf统计SLURM分配的资源，实时监控显示实际系统消耗
2. **准确性**: jobperf更准确用于计费和资源核算，实时监控更适合性能调优
3. **时间粒度**: jobperf采样间隔较长，实时监控提供更细粒度的时间序列数据
4. **集成度**: jobperf与SLURM调度器深度集成，实时监控提供独立视角

## 故障排除

### 常见问题

1. **作业失败**
   ```bash
   # 检查错误日志
   cat hmm_search_<job_id>.err
   
   # 检查模块加载
   module list
   ```

2. **监控数据缺失**
   ```bash
   # 检查监控进程是否正常启动
   ps aux | grep jobperf
   ps aux | grep iostat
   ```

3. **资源不足**
   ```bash
   # 检查可用资源
   sinfo -p compute
   
   # 调整CPU请求
   # 修改脚本中的 #SBATCH --cpus-per-task=40
   ```

### 性能优化建议

1. **CPU利用率低**: 减少每个hmmscan的线程数，增加并行作业数
2. **内存不足**: 减少并行作业数或增加内存请求
3. **I/O瓶颈**: 考虑使用SSD存储或减少I/O密集型操作

## 依赖要求

### 软件模块
- `parallel`: GNU parallel工具
- `hmmer`: HMMER生物信息学工具包

### 系统工具
- `jobperf`: SLURM资源监控工具
- `iostat`: 系统I/O监控工具
- `top`: 系统进程监控工具
- `free`: 内存使用监控工具

## 输出文件

### 主要输出
- `hmm_out/*.out`: HMMER搜索结果
- `hmm_out/*.domtblout`: 域表输出文件

### 监控输出
- `monitoring_output/jobperf_output.txt`: SLURM作业性能数据
- `monitoring_output/system_stats.csv`: 实时系统统计
- `monitoring_output/iostat_output.txt`: I/O性能数据

## 注意事项

1. **资源限制**: 确保请求的CPU核心数不超过节点可用资源
2. **存储空间**: 监控数据会占用额外存储空间，注意清理旧数据
3. **权限问题**: 确保对工作目录有写权限
4. **模块依赖**: 确保所需模块已正确加载

## 联系信息

如有问题或建议，请联系系统管理员或查看SLURM文档。

---
*最后更新: $(date)*
