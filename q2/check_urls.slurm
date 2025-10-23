#!/bin/bash
#SBATCH --job-name=check_urls
#SBATCH --output=check_urls_%j.out
#SBATCH --error=check_urls_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mail-type=ALL
#SBATCH --nodes=1


module load intel/2018.2 gsl/2.4
module load gnu-parallel

FILE="URLsFile.txt"
CPUS=$SLURM_CPUS_PER_TASK

cat "$FILE" | nl -ba | parallel -j $CPUS --colsep '\t' '
    line={1}
    url={2}
    echo "$(date "+%H:%M:%S") [START] Line $line: $url"
    wget -q --spider "$url"
    if [ $? -ne 0 ]; then
        echo "$(date "+%H:%M:%S") [FAIL] Line $line: $url" | tee -a failed_urls.log
    else
        echo "$(date "+%H:%M:%S") [OK]   Line $line: $url"
    fi
'
