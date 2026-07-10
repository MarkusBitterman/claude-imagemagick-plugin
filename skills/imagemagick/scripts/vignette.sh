#!/usr/bin/env sh
# vignette.sh — preset vignettes: soft | dark | white | grunge.
# Usage: vignette.sh in.jpg out.jpg [preset]
#   soft   — gentle corner darkening, center untouched (default)
#   dark   — classic heavy oval vignette (IM's built-in -vignette)
#   white  — faded light edges, "dreamy portrait" look
#   grunge — irregular noisy dark edge
# Masks use -define gradient:extent=DiagonalDistance so the falloff reaches
# the corners (a bare radial-gradient goes black at the edge midpoints and
# clips the corners flat); -level holds the center pure white so multiply
# doesn't dim the whole frame.
set -eu

in=$1
out=$2
preset=${3:-soft}

w=$(magick identify -format '%w' "$in")
h=$(magick identify -format '%h' "$in")
min=$(( w < h ? w : h ))

case $preset in
  soft)
    magick "$in" \
      \( -size "${w}x${h}" -define gradient:extent=DiagonalDistance \
         radial-gradient:white-black -level 0%,55% +level 35%,100% -blur 0x20 \) \
      -compose multiply -composite "$out" ;;
  dark)
    magick "$in" -background black \
      -vignette "0x$((min/20))+$((min/20))+$((min/20))" "$out" ;;
  white)
    magick "$in" \
      \( -size "${w}x${h}" -define gradient:extent=DiagonalDistance \
         radial-gradient:black-white -level 45%,100% +level 0%,80% -blur 0x20 \) \
      -compose screen -composite "$out" ;;
  grunge)
    # -spread + noise roughen the edge; the trailing -level re-pins whites
    # the noise pass greyed out, else the center dims too.
    magick "$in" \
      \( -size "${w}x${h}" -define gradient:extent=DiagonalDistance \
         radial-gradient:white-black -level 0%,60% +level 20%,100% \
         -spread 18 -attenuate 0.35 +noise Gaussian -blur 0x6 \
         -colorspace Gray -level 8%,92% \) \
      -compose multiply -composite "$out" ;;
  *)
    echo "unknown preset '$preset' (soft|dark|white|grunge)" >&2; exit 2 ;;
esac
magick identify "$out"
