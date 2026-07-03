#!/usr/bin/env sh
# browser-mockup.sh — wrap a screenshot in a browser-window frame: title bar
# with traffic-light dots, URL pill, rounded corners, drop shadow.
# Usage: browser-mockup.sh screenshot.png mockup.png ["example.com"]
# Output is a transparent-background PNG ready to drop on any page.
set -eu
in=$1
out=$2
url=${3:-example.com}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

W=$(magick identify -format %w "$in")
H=$(magick identify -format %h "$in")

# Bar height scales with width, clamped to sane pixel sizes.
BAR=$((W / 18)); [ "$BAR" -lt 32 ] && BAR=32; [ "$BAR" -gt 56 ] && BAR=56
R=$((BAR / 4))                     # window corner radius
DOT=$((BAR / 8))                   # traffic-light dot radius
CY=$((BAR / 2))
TH=$((H + BAR))

# 1. Title bar: three dots and a URL pill drawn onto a light chrome strip.
PX1=$((BAR * 2)); PX2=$((W - BAR)); PY1=$((BAR * 22 / 100)); PY2=$((BAR * 78 / 100))
magick -size "${W}x${BAR}" xc:'#dee1e6' \
  -fill '#ff5f57' -draw "circle $((BAR/2)),$CY $((BAR/2 + DOT)),$CY" \
  -fill '#febc2e' -draw "circle $((BAR/2 + 3*DOT)),$CY $((BAR/2 + 4*DOT)),$CY" \
  -fill '#28c840' -draw "circle $((BAR/2 + 6*DOT)),$CY $((BAR/2 + 7*DOT)),$CY" \
  -fill white -draw "roundrectangle $PX1,$PY1 $PX2,$PY2 $(( (PY2-PY1)/2 )),$(( (PY2-PY1)/2 ))" \
  -fill '#5f6368' -pointsize $((BAR * 38 / 100)) \
  -draw "text $((PX1 + BAR/2)),$((BAR * 62 / 100)) '$url'" \
  "$tmp/bar.png"

# 2. Stack bar over screenshot, then round the window corners with an alpha
#    mask (white roundrectangle = keep, black = clip).
magick "$tmp/bar.png" "$in" -append "$tmp/window.png"
magick -size "${W}x${TH}" xc:black \
  -fill white -draw "roundrectangle 0,0 $((W-1)),$((TH-1)) $R,$R" "$tmp/mask.png"
magick "$tmp/window.png" "$tmp/mask.png" -alpha off -compose copy_opacity -composite \
  "$tmp/rounded.png"

# 3. Drop shadow on a transparent canvas, with margin so nothing clips.
magick "$tmp/rounded.png" \( +clone -background black -shadow 45x12+0+10 \) +swap \
  -background none -layers merge +repage "$out"

magick identify "$out"
