#!/bin/bash
#SBATCH --job-name=detecting_files
#SBATCH --output=detecting_files%j.out
#SBATCH --error=detecting_files%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --partition=compute
#SBATCH --mail-type=ALL
#SBATCH --nodes=1

FILE="file_list.txt"

echo "detecting the missing file"

CPUS=$SLURM_CPUS_PER_TASK

cat "$FILE" | nl -ba | parallel -j $CPUS --colsep '\t' '
    line_num={1}
    path={2}
    if [ ! -e "$path" ]; then
        echo "Line $line_num: $path cannot find the file"
    fi
'

