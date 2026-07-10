#!/usr/bin/env sh
# tilt-shift.sh — fake a miniature-model look: sharp focus band, blur
# growing above and below, boosted saturation.
# Usage: tilt-shift.sh in.jpg out.jpg [focus%] [band%] [blur]
#   focus% — vertical center of the sharp band, 0=top 100=bottom (default 55)
#   band%  — half-height of the fully sharp zone (default 10)
#   blur   — max blur sigma at the frame edges (default 8)
# Pick the focus line on the subject, not the horizon: the miniature
# illusion comes from the subject being sharp while ground nearer than it
# and sky beyond it melt away.
set -eu

in=$1
out=$2
focus=${3:-55}
band=${4:-10}
blur=${5:-8}

w=$(magick identify -format '%w' "$in")
h=$(magick identify -format '%h' "$in")

# Mask: black = keep sharp, white = take the blurred clone. Built with -fx
# on a 1-pixel column then stretched to full size — orders of magnitude
# faster than running -fx per pixel on the real image.
magick "$in" \
  \( +clone -blur "0x${blur}" \) \
  \( -size "1x${h}" xc: -fx "clamp((abs(j/h-${focus}/100)-${band}/100)*4)" \
     -scale "${w}x${h}!" \) \
  -composite -modulate 104,140 -sigmoidal-contrast 3x50% "$out"
magick identify "$out"
