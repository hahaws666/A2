Parameter instructions:

You may set the following environment variables (optional):
```
export SLURM_CPUS_PER_TASK=40
export WORKING_DIR="/your/working/directory/path"
export THUMBNAIL_DIR="thumbnails"
```

Then submit the job script:
```
sbatch thumbnail_parallel.slurm
```
