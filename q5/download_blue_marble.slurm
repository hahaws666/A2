#!/bin/bash
#SBATCH --job-name=download_blue_marble
#SBATCH --output=download_blue_marble_%j.out
#SBATCH --error=download_blue_marble_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mail-type=ALL
#SBATCH --nodes=1


# module load intel/2018.2 gsl/2.4
# module load gnu-parallel

CPUS=$SLURM_CPUS_PER_TASK


# --- NASA WMTS settings ---
export base="https://map1a.vis.earthdata.nasa.gov/wmts-geo/wmts.cgi"
export service="SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0"
export layer="LAYER=BlueMarble_ShadedRelief_Bathymetry"
export set="STYLE=&TILEMATRIXSET=EPSG4326_500m&TILEMATRIX=5"
export format="FORMAT=image%2Fjpeg"
export OUTPUT_DIR="blue_marble"

mkdir -p $OUTPUT_DIR

ROWS=$(seq 0 8)
COLS=$(seq 0 16)

# generate the tile list
parallel echo {1} {2} ::: $ROWS ::: $COLS > tile_list.txt


cat tile_list.txt | parallel -j "$CPUS" --colsep ' ' \
  --env base,service,layer,set,format,OUTPUT_DIR '
    row={1}; col={2};
    url="$base?$service&$layer&$set&TILEROW=$row&TILECOL=$col&$format";
    outfile="$OUTPUT_DIR/blue_marble_${row}_${col}.jpg";
    echo "$url"
    wget -q -nc -O "$outfile" "$url" || echo "FAILED $row $col $url" >> failed_tiles.log
'


# # --- summary ---
# total=$(wc -l < tile_list.txt)
# downloaded=$(ls "$OUTPUT_DIR"/*.jpg 2>/dev/null | wc -l || echo 0)
# failed=$(( total - downloaded ))

# concating the tiles into a full image
seq 0 7 | parallel "convert $(printf 'blue_marble/blue_marble_{}_%d.jpg ' $(seq 0 15)) +append row_{}.jpg"
convert $(printf "row_%d.jpg " $(seq 0 7)) -append blue_marble_full.jpg
rm -f row_*.jpg

