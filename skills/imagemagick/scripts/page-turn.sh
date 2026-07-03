#!/usr/bin/env sh
# page-turn.sh — lift the bottom-right corner of an image in a page turn:
# corner clipped away, gradient-shaded flap folded back over the page, shadow
# under the lifted paper. Output has a transparent corner for overlay use.
# Usage: page-turn.sh input.png curled.png [curl-fraction 0..100, default 35]
set -eu
in=$1
out=$2
pct=${3:-35}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

W=$(magick identify -format %w "$in")
H=$(magick identify -format %h "$in")
MIN=$W; [ "$H" -lt "$MIN" ] && MIN=$H
C=$((MIN * pct / 100))             # curl triangle leg length

# 1. Clip the corner: alpha mask removes the triangle the page curls away from.
magick -size "${W}x${H}" xc:white -fill black \
  -draw "polygon $((W-C)),$H $W,$H $W,$((H-C))" "$tmp/cut.png"
magick "$in" "$tmp/cut.png" -alpha off -compose copy_opacity -composite "$tmp/page.png"

# 2. Shadow under the lift: a dark blurred band along the fold line, masked so
#    it only darkens the page (not the transparent corner).
magick -size "${W}x${H}" xc:none -stroke 'rgba(0,0,0,0.45)' -strokewidth $((C / 6 + 2)) \
  -draw "line $((W-C)),$H $W,$((H-C))" -blur "0x$((C / 12 + 2))" "$tmp/shadow.png"
magick "$tmp/page.png" "$tmp/shadow.png" -compose atop -composite "$tmp/shadowed.png"

# 3. The flap: the cut corner folded back across the fold line becomes the
#    triangle (W-C,H) (W,H-C) (W-C,H-C). Fill it with a diagonal gradient —
#    bright at the crease (catching light), dimming toward the curled tip —
#    by rotating a linear gradient 45 degrees and masking to the triangle.
D=$((C * 3 / 2))
magick -size "${D}x${D}" gradient:'gray(150)-gray(252)' -rotate 45 \
  -gravity center -extent "${C}x${C}" +repage "$tmp/grad.png"
magick -size "${C}x${C}" xc:black -fill white \
  -draw "polygon 0,$C $C,0 0,0" "$tmp/tri.png"
# NB: -compose is sticky — reset to over before the shadow merge, or the
# preceding copy_opacity corrupts -layers merge.
magick "$tmp/grad.png" "$tmp/tri.png" -alpha off -compose copy_opacity -composite \
  -compose over \( +clone -background black -shadow 40x3+2+2 \) +swap \
  -background none -layers merge +repage "$tmp/flap.png"

# 4. Set the flap onto the page at the corner.
magick "$tmp/shadowed.png" "$tmp/flap.png" \
  -geometry "+$((W-C-2))+$((H-C-2))" -compose over -composite "$out"

magick identify "$out"
