#!/usr/bin/env sh
# watermark-batch.sh — stamp a watermark onto every image in a directory,
# scaled relative to each image, into a NEW directory (originals untouched).
# Usage: watermark-batch.sh wm.png indir/ outdir/ [gravity] [opacity%] [scale%]
#   gravity  — corner/edge for the stamp (default southeast)
#   opacity% — watermark strength via dissolve (default 45)
#   scale%   — watermark width as a percent of each image's width (default 18)
# The margin scales with the watermark (a fixed pixel margin looks huge on
# thumbnails and invisible on 6000px photos). A failed file is recorded in
# outdir/failures.txt and never aborts the batch.
set -eu

wm=$1
indir=$2
outdir=$3
gravity=${4:-southeast}
opacity=${5:-45}
scale=${6:-18}

[ -d "$outdir" ] || mkdir -p "$outdir"
: > "$outdir/failures.txt"
count=0

for f in "$indir"/*; do
  [ -f "$f" ] || continue
  case $f in
    *.jpg|*.JPG|*.jpeg|*.JPEG|*.png|*.PNG|*.webp|*.WEBP|*.tif|*.TIF|*.tiff|*.TIFF) ;;
    *) continue ;;
  esac
  base=${f##*/}
  w=$(magick identify -format '%w' "$f")
  wmw=$((w * scale / 100))
  margin=$((wmw / 8))
  magick "$f" \( "$wm" -resize "${wmw}x" \) \
    -gravity "$gravity" -geometry "+${margin}+${margin}" \
    -compose dissolve -define compose:args="$opacity" -composite \
    "$outdir/$base" || { echo "$f" >> "$outdir/failures.txt"; continue; }
  count=$((count + 1))
done

fails=$(wc -l < "$outdir/failures.txt")
[ "$fails" -eq 0 ] && rm -f "$outdir/failures.txt"
echo "$count watermarked into $outdir/, $fails failed"
