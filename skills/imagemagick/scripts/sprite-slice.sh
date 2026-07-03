#!/usr/bin/env sh
# sprite-slice.sh — cut a sprite sheet into equal tiles, or reassemble tiles.
# Usage: sprite-slice.sh sheet.png 32x32 out_dir/          # slice
#        sprite-slice.sh --assemble 8 sheet.png tile*.png  # 8 columns wide
# Slicing uses IM's grid crop: '-crop WxH' with no offset tiles the whole
# image. Sheets not evenly divisible by the tile size produce smaller
# remnant tiles at the right/bottom edges.
set -eu

if [ "$1" = "--assemble" ]; then
  cols=$2
  out=$3
  shift 3
  magick montage "$@" -tile "${cols}x" -geometry +0+0 -background none "$out"
  magick identify "$out"
  exit 0
fi

sheet=$1
tile=$2
dir=${3:-tiles}
mkdir -p "$dir"

# +repage drops each tile's virtual-canvas offset; +adjoin forces one file
# per tile even for multi-image-capable formats.
magick "$sheet" -crop "$tile" +repage +adjoin "$dir/tile_%03d.png"

count=$(ls "$dir" | wc -l)
echo "$count tiles of $tile written to $dir/"
