#!/usr/bin/env sh
# paper-stack.sh — typeset a text file (plain text, markdown source, code…)
# into letter pages and photograph them as a loose stack: each sheet rotated
# a little differently, drop shadows between sheets, transparent background.
# Usage: paper-stack.sh input.txt stack.png [max-pages, default 3]
set -eu
in=$1
out=$2
want=${3:-3}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 1. Typeset every page ('text:' paginates at letter size), then keep at most
#    $want of them. +adjoin forces one PNG per page. The text: delegate does
#    not word-wrap, so soft-wrap long lines first.
fold -s -w 92 "$in" > "$tmp/wrapped.txt"
magick -density 100 "text:$tmp/wrapped.txt" -bordercolor white -border 24 \
  -colorspace sRGB +adjoin "$tmp/page_%03d.png"
total=$(ls "$tmp"/page_*.png | wc -l)
n=$want; [ "$total" -lt "$n" ] && n=$total

# 2. Deterministic "mess": per-sheet rotation and drift, bottom sheet first.
#    (Fixed tables, so the same input always yields the same stack.)
angles="-8 6 -3 5 -1"
xoffs="26 -20 12 -14 0"
yoffs="18 14 -10 8 0"

W=$(magick identify -format %w "$tmp/page_000.png")
H=$(magick identify -format %h "$tmp/page_000.png")
CW=$((W * 13 / 10)); CH=$((H * 13 / 10))
magick -size "${CW}x${CH}" xc:none "$tmp/stack.png"

i=$((n - 1))                       # last wanted page sits at the bottom
layer=1
while [ "$i" -ge 0 ]; do
  # pick the layer-th entry of each table
  a=$(echo "$angles" | cut -d' ' -f$layer)
  dx=$(echo "$xoffs" | cut -d' ' -f$layer)
  dy=$(echo "$yoffs" | cut -d' ' -f$layer)
  # top sheet (i=0) always lies nearly straight: force the final table slot
  [ "$i" -eq 0 ] && { a=-1; dx=0; dy=0; }

  # rotate the sheet, give it its own soft shadow, then drop it on the pile
  magick "$tmp/$(printf 'page_%03d.png' "$i")" -background none -rotate "$a" \
    -compose over \( +clone -background black -shadow 35x7+6+9 \) +swap \
    -background none -layers merge +repage "$tmp/sheet.png"
  magick "$tmp/stack.png" "$tmp/sheet.png" -gravity center \
    -geometry "$(printf '%+d%+d' "$dx" "$dy")" -composite "$tmp/stack.png"

  i=$((i - 1)); layer=$((layer + 1))
done

# 3. Trim the transparent margin back to the pile, keep a little breathing room.
magick "$tmp/stack.png" -trim +repage -bordercolor none -border 20 "$out"
magick identify "$out"
