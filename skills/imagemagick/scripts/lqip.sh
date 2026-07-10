#!/usr/bin/env sh
# lqip.sh — low-quality image placeholder: prints a tiny base64 WebP data
# URI (typically 100–300 bytes) to stdout, for inlining into HTML/CSS while
# the real image loads.
# Usage: lqip.sh in.jpg [width] [preview.png]
#   width       — placeholder pixel width (default 24)
#   preview.png — optional: also write the placeholder upscaled back to the
#                 original size, to preview what a CSS-blurred render shows
# stdout carries ONLY the data URI (pipeable); the size report goes to
# stderr. -strip matters: an ICC profile alone can outweigh the pixels.
set -eu

in=$1
width=${2:-24}
preview=${3:-}

tmp=$(mktemp --suffix=.webp)
trap 'rm -f "$tmp"' EXIT

magick "$in" -auto-orient -thumbnail "${width}x" -strip -quality 60 "$tmp"
printf 'data:image/webp;base64,%s\n' "$(base64 -w0 "$tmp")"
echo "placeholder: $(wc -c < "$tmp") bytes ($(magick identify -format '%wx%h' "$tmp"))" >&2

if [ -n "$preview" ]; then
  size=$(magick identify -format '%wx%h' "$in")
  magick "$tmp" -filter Gaussian -resize "${size}!" "$preview"
  echo "preview: $preview" >&2
fi
