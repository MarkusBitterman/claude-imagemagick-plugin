#!/usr/bin/env sh
# qr-brand.sh — generate a brand-colored QR code, optionally with a center
# logo. Requires qrencode (ImageMagick cannot compute QR error-correction
# itself): apt install qrencode / nix shell nixpkgs#qrencode
# Usage: qr-brand.sh "text-or-url" out.png [fg] [bg] [logo.png]
#   fg/bg — module and background colors (default #000000 on white)
# Scannability guardrails baked in: error-correction level H (~30% damage
# tolerance) so the logo can cover the center; logo capped at 20% of QR
# width; -filter point scaling keeps module edges crisp. Keep fg-on-bg
# contrast HIGH and fg DARKER than bg — scanners assume dark-on-light.
# Verify with a real scan (zbarimg out.png) before printing anything.
set -eu

text=$1
out=$2
fg=${3:-#000000}
bg=${4:-white}
logo=${5:-}
size=600

command -v qrencode >/dev/null || {
  echo "qrencode not found (apt install qrencode / nix shell nixpkgs#qrencode)" >&2
  exit 3
}

tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT
qrencode -o "$tmp" -s 1 -m 4 -l H "$text"

# -s 1 modules are exactly 1px and aliasing-free, so plain -opaque swaps
# recolor cleanly; point-filter upscaling keeps them square.
magick "$tmp" -fill "$fg" -opaque black -fill "$bg" -opaque white \
  -filter point -resize "${size}x${size}" "$out"

if [ -n "$logo" ]; then
  logow=$((size / 5))
  pad=$((logow + size / 30))
  magick "$out" \
    \( "$logo" -resize "${logow}x${logow}" -background "$bg" \
       -gravity center -extent "${pad}x${pad}" \) \
    -gravity center -composite "$out"
fi

magick identify "$out"
if command -v zbarimg >/dev/null; then
  decoded=$(zbarimg -q "$out" 2>/dev/null | sed 's/^QR-Code://') || decoded=
  [ "$decoded" = "$text" ] && echo "scan check: OK" \
    || { echo "scan check: FAILED — increase contrast or drop the logo" >&2; exit 4; }
else
  echo "scan check skipped (zbarimg not installed — verify before printing)"
fi
