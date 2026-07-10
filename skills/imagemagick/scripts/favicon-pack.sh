#!/usr/bin/env sh
# favicon-pack.sh — logo to a complete favicon set: multi-resolution
# favicon.ico (48/32/16), apple-touch-icon (180), and PWA icons (192/512).
# Usage: favicon-pack.sh logo.png outdir/ [bgcolor]
#   bgcolor — background for the apple-touch icon (default white); iOS
#             renders transparent apple-touch icons on black, so it gets
#             flattened while the PNG/ICO icons keep their alpha.
# Non-square logos are padded (transparently) to centered squares, never
# stretched. Prints the matching HTML <link> snippet when done.
# Detailed logos turn to mush at 16px — check favicon.ico[2] and consider
# feeding a simplified glyph-only variant instead of the full logo.
set -eu

logo=$1
dir=${2:-favicons}
bg=${3:-white}
mkdir -p "$dir"

# pad to square on the larger edge
max=$(magick identify -format '%[fx:max(w,h)]' "$logo")
sq="$dir/.square-$$.png"
trap 'rm -f "$sq"' EXIT
magick "$logo" -background none -gravity center -extent "${max}x${max}" "$sq"

magick "$sq" -define icon:auto-resize=48,32,16 "$dir/favicon.ico"
magick "$sq" -resize 180x180 -background "$bg" -flatten "$dir/apple-touch-icon.png"
magick "$sq" -resize 192x192 "$dir/icon-192.png"
magick "$sq" -resize 512x512 "$dir/icon-512.png"

magick identify "$dir/favicon.ico" "$dir/apple-touch-icon.png" \
  "$dir/icon-192.png" "$dir/icon-512.png"
cat <<'HTML'
<link rel="icon" href="/favicon.ico" sizes="48x48 32x32 16x16">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="icon" type="image/png" sizes="192x192" href="/icon-192.png">
<link rel="icon" type="image/png" sizes="512x512" href="/icon-512.png">
HTML
