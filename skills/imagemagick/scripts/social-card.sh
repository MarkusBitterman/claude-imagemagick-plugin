#!/usr/bin/env sh
# social-card.sh — generate an Open Graph / social preview card (1200x630):
# dark gradient field, accent bar, big title, dimmer subtitle, footer domain.
# Usage: social-card.sh out.png "Title text" ["subtitle"] ["domain.dev"]
# Word-wraps the title automatically via caption:.
set -eu
out=$1
title=$2
sub=${3:-}
domain=${4:-}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

FONT=DejaVu-Sans; FONT_BOLD=DejaVu-Sans-Bold
magick -list font | grep -q "Font: $FONT_BOLD" || { FONT=helvetica; FONT_BOLD=helvetica-bold; }

# 1. Field: dark vertical gradient plus a soft glow pushed toward the
#    top-left. The glow is an opaque dark radial — screening a dark layer
#    lightens gently; a translucent bright one would wash the whole card.
magick -size 1200x630 gradient:'#1b2a3a-#0c1118' -rotate 180 \
  \( -size 1200x630 radial-gradient:'#2a5878-#000000' \
     -virtual-pixel background -background black \
     -distort SRT '600,315 1 0 300,190' \) -compose screen -composite \
  "$tmp/field.png"

# 2. Accent bar + title (caption: wraps within the box) + subtitle + domain.
magick "$tmp/field.png" \
  -fill '#4cc9f0' -draw 'rectangle 90,150 102,240' \
  \( -size 940x300 -background none -font "$FONT_BOLD" -fill white \
     caption:"$title" \) -geometry +130+140 -composite \
  "$tmp/card.png"
[ -n "$sub" ] && magick "$tmp/card.png" \
  \( -size 940x120 -background none -font "$FONT" -fill '#8ea6b8' \
     caption:"$sub" \) -geometry +130+430 -composite "$tmp/card.png"
[ -n "$domain" ] && magick "$tmp/card.png" -font "$FONT" -pointsize 26 \
  -fill '#4cc9f0' -gravity southwest -annotate +130+48 "$domain" "$tmp/card.png"

cp "$tmp/card.png" "$out"
magick identify "$out"
