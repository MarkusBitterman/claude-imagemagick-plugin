#!/usr/bin/env sh
# age-paper.sh — weather a document image into old, coffee-stained paper:
# parchment tint, mottled fiber texture, burned edges, stain ring, rough edges.
# Usage: age-paper.sh input.png aged.png
# Works best on light/document-like inputs (scans, fold-paper.sh output).
set -eu
in=$1
out=$2
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

W=$(magick identify -format %w "$in")
H=$(magick identify -format %h "$in")

# 1. Parchment tint: desaturate a little, multiply with an aged-paper color.
#    Force sRGB first — on a grayscale input the composite would otherwise
#    collapse to the base image's gray colorspace and drop the tint.
magick "$in" -colorspace sRGB -type TrueColor -modulate 102,55,100 \
  \( -size "${W}x${H}" xc:'#dcc292' \) -compose multiply -composite "$tmp/tinted.png"

# 2. Fiber mottle: soft random plasma compressed to midtones (+level squeezes
#    the range INTO 35–65% — plain -level would stretch it and wash the tint).
magick -size "${W}x${H}" plasma:fractal -blur 0x2 -colorspace Gray \
  +level 35%,65% "$tmp/mottle.png"
# (-compose overlay, not softlight: softlight blows midtone overlays to white
# on IM 7.1.2 Q16-HDRI — verified empirically.)
magick "$tmp/tinted.png" "$tmp/mottle.png" -compose overlay -composite "$tmp/mottled.png"

# 3. Edge burn: inverted radial gradient multiplied in, darkest at the corners.
magick -size "${W}x${H}" radial-gradient:'gray(255)-gray(195)' "$tmp/burn.png"
magick "$tmp/mottled.png" "$tmp/burn.png" -compose multiply -composite "$tmp/burned.png"

# 4. Coffee ring: two offset partial ellipse strokes (cup rocked twice) plus a
#    faint filled spill, blurred hard so it reads as soaked-in, not drawn.
CX=$((W * 70 / 100)); CY_=$((H * 22 / 100)); RX=$((W / 8)); RY=$((W / 9))
magick -size "${W}x${H}" xc:none -fill none \
  -stroke 'rgba(110,70,25,0.50)' -strokewidth $((W / 90 + 2)) \
  -draw "ellipse $CX,$CY_ $RX,$RY 25,330" \
  -stroke 'rgba(90,55,20,0.35)' -strokewidth $((W / 140 + 1)) \
  -draw "ellipse $((CX + RX/12)),$((CY_ + RY/14)) $((RX * 96/100)),$((RY * 97/100)) 300,190" \
  -stroke none -fill 'rgba(140,95,40,0.12)' \
  -draw "ellipse $CX,$CY_ $((RX * 94/100)),$((RY * 94/100)) 0,360" \
  -blur 0x3 "$tmp/ring.png"
magick "$tmp/burned.png" "$tmp/ring.png" -compose multiply -composite "$tmp/stained.png"

# 5. Rough edges: noise-eaten border mask via copy_opacity (transparent nicks).
magick -size "${W}x${H}" xc:black -fill white \
  -draw "rectangle 6,6 $((W-7)),$((H-7))" -spread 5 -blur 0x1 -threshold 55% \
  "$tmp/edgemask.png"
magick "$tmp/stained.png" "$tmp/edgemask.png" -alpha off -compose copy_opacity -composite "$out"

magick identify "$out"
