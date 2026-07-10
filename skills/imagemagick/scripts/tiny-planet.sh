#!/usr/bin/env sh
# tiny-planet.sh — wrap a landscape/panorama into a "tiny planet" disc.
# Usage: tiny-planet.sh in.jpg out.png [size] [--sky-center]
# Ground lands at the center (input is rotated 180 before the polar wrap);
# --sky-center skips the rotation for the inverted "tunnel" look.
# -virtual-pixel edge extends the sky into the square's corners; wider-than-
# tall inputs work best — true 360° panoramas wrap seamlessly, ordinary
# photos show a vertical seam where the left and right edges meet.
set -eu

in=$1
out=$2
size=${3:-1000}
rotate=180
[ "${4:-}" = "--sky-center" ] && rotate=0

magick "$in" -resize "${size}x${size}!" -rotate "$rotate" \
  -virtual-pixel edge -distort Polar 0 "$out"
magick identify "$out"
