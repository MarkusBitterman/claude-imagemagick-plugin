#!/usr/bin/env sh
# fold-paper.sh — typeset a .txt file as a tri-folded letter with creases and shadow.
# Usage: fold-paper.sh input.txt output.png
# The whole pipeline is ImageMagick 7; no GUI was harmed.
set -eu
in=$1
out=$2
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 1. Typeset the first page ('text:' paginates plain text at letter size).
#    Quote the [0] frame index — brackets glob in most shells.
magick -density 120 "text:${in}[0]" -bordercolor white -border 30 \
  -colorspace sRGB "$tmp/page.png"

W=$(magick identify -format %w "$tmp/page.png")
H=$(magick identify -format %h "$tmp/page.png")
H3=$((H / 3))
HR=$((H - 2 * H3))
Y1=$H3
Y2=$((2 * H3))

# 2. Tri-fold lighting: each panel gets its own vertical gradient, multiplied
#    onto the page so paper texture/text show through the shading.
magick -size "${W}x${H3}" "gradient:gray(255)-gray(205)" \
  \( -size "${W}x${H3}" "gradient:gray(228)-gray(255)" \) \
  \( -size "${W}x${HR}" "gradient:gray(255)-gray(212)" \) \
  -append "$tmp/shade.png"
magick "$tmp/page.png" "$tmp/shade.png" -compose multiply -composite \
  "$tmp/shaded.png"

# 3. Crease lines at the fold boundaries: a dark line with a bright line
#    beneath reads as a paper crease catching the light.
magick "$tmp/shaded.png" -strokewidth 1 \
  -stroke 'gray(150)' -draw "line 0,$Y1 $W,$Y1" \
  -stroke 'gray(252)' -draw "line 0,$((Y1 + 1)) $W,$((Y1 + 1))" \
  -stroke 'gray(150)' -draw "line 0,$Y2 $W,$Y2" \
  -stroke 'gray(252)' -draw "line 0,$((Y2 + 1)) $W,$((Y2 + 1))" \
  "$tmp/creased.png"

# 4. Gentle perspective so the page sits off-square, then a soft drop shadow.
magick "$tmp/creased.png" -virtual-pixel transparent -background none \
  -distort Perspective \
    "0,0 16,8  $W,0 $((W - 10)),0  0,$H 8,$((H - 6))  $W,$H $((W - 2)),$((H - 16))" \
  \( +clone -background black -shadow 50x9+12+16 \) +swap \
  -background white -layers merge +repage "$out"

magick identify "$out"
