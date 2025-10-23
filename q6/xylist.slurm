#!/bin/bash
#SBATCH --job-name=xylist
#SBATCH --output=sylist_%j.out
#SBATCH --error=sylist_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mail-type=ALL
#SBATCH --nodes=1

CPUS=$SLURM_CPUS_PER_TASK

parallel echo X={1} Y={2} :::: xlist.txt :::: ylist.txt
