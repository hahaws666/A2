#!/bin/bash
#SBATCH --job-name=thumbnail_parallel
#SBATCH --output=thumbnail_%j.out
#SBATCH --error=thumbnail_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --partition=compute
#SBATCH --mail-type=ALL
#SBATCH --nodes=1



# set working directory
if not $WORKING_DIR; then
    WORKING_DIR="/home/l/lcl_uotcscd71/lcl_uotcscd71s1408/A2/q1/sample_dir"
fi
cd /home/l/lcl_uotcscd71/lcl_uotcscd71s1408/A2/q1/sample_dir

# get the number of CPU cores
CPUS=$SLURM_CPUS_PER_TASK

# make output directory (default: thumbnails)
if not $THUMBNAIL_DIR; then
    THUMBNAIL_DIR="thumbnails"
fi
mkdir -p $THUMBNAIL_DIR

echo "Start parallel processing of image thumbnails..."
echo "Using $CPUS CPU cores"
echo "Processing time: $(date)"

# Use GNU parallel to process all jpg files
find . -name "*.jpg" -type f | parallel -j $CPUS --progress \
    "convert -geometry 120 {} $THUMBNAIL_DIR/thumb_{/}"

# 统计处理结果
total_files=$(find . -name "*.jpg" -type f | wc -l)
processed_files=$(find $THUMBNAIL_DIR -name "thumb_*.jpg" -type f | wc -l)

echo "done: $(date)"
echo "total files: $total_files"
echo "processed files: $processed_files"

# show some example results
echo "generated thumbnail examples:"
ls -la $THUMBNAIL_DIR/ | head -10
