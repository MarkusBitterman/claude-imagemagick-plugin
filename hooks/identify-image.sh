#!/usr/bin/env sh
# PostToolUse sanity check for the imagemagick plugin.
#
# After Claude runs a Bash command that invoked ImageMagick/GraphicsMagick, this
# identifies the output image and hands Claude a one-line summary (format, size,
# depth, colorspace, file size) — or a warning if the file came out 0 bytes or
# isn't a decodable image. That catches the silent failures: a blown-out write,
# a typo'd geometry, an encoder that produced nothing.
#
# Contract: reads the hook payload as JSON on stdin, prints hook JSON on stdout,
# ALWAYS exits 0. It is read-only and never blocks a tool call.
#   - Needs `jq` or `python3` to read the payload; no-ops silently without both.
#   - Finds the output via the IM7 rule "output is the last argument", so it
#     covers `magick … out.png` and our scripts' `script.sh in out.png`; it
#     skips `mogrify` (in-place / multi-file — no single output to check).
#   - Disable entirely with:  IMAGEMAGICK_HOOK_DISABLE=1
set -u

quiet() { exit 0; }                 # nothing worth saying
emit()  { printf '%s\n' "$1"; exit 0; }

[ "${IMAGEMAGICK_HOOK_DISABLE:-}" = 1 ] && quiet
command -v magick >/dev/null 2>&1 || quiet

payload=$(cat)

# Pull one string field (dotted path) out of the payload. jq first, else python3.
field() {   # field <jq-path> <python-dotted-path>
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$payload" | python3 -c 'import sys,json
try: d=json.load(sys.stdin)
except Exception: print(""); sys.exit(0)
cur=d
for k in sys.argv[1].split("."):
    cur = cur.get(k) if isinstance(cur, dict) else None
print(cur if isinstance(cur, str) else "")' "$2" 2>/dev/null
  fi
}

cmd=$(field '.tool_input.command' 'tool_input.command')
[ -n "$cmd" ] || quiet

# React only to magick/convert/gm; skip mogrify (no single output token).
printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])(magick|convert|gm)([^[:alnum:]_]|$)' || quiet
printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_])mogrify([^[:alnum:]_]|$)' && quiet

# Candidate output = last whitespace token, stripped of quotes and trailing
# shell punctuation (IM7: the output file is the last argument).
out=$(printf '%s' "$cmd" | awk '{print $NF}' | sed "s/[;&|'\"]*$//; s/^['\"]*//")
[ -n "$out" ] || quiet
# Drop a leading write-format hint like png32: or jpeg: if the rest is a file.
case "$out" in *:*) rest=${out#*:}; [ -f "$rest" ] && out=$rest ;; esac

# Only image-looking outputs. Anything else (info:, a .txt redirect, a pseudo
# format) falls through to silence.
case "$out" in
  *.png|*.PNG|*.jpg|*.JPG|*.jpeg|*.JPEG|*.webp|*.WEBP|*.gif|*.GIF|\
  *.tif|*.tiff|*.TIF|*.TIFF|*.avif|*.AVIF|*.heic|*.HEIC|*.bmp|*.BMP|\
  *.ico|*.ICO|*.ppm|*.pgm|*.pnm|*.jxl|*.JXL) : ;;
  *) quiet ;;
esac

# Resolve against the tool's cwd if it isn't found relative to ours.
cwd=$(field '.cwd' 'cwd')
[ -f "$out" ] || { [ -n "$cwd" ] && [ -f "$cwd/$out" ] && out="$cwd/$out"; }
[ -f "$out" ] || quiet          # glob/multiple/again-relative — nothing single to check

base=$(basename "$out")
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
warn() {   # warn <message> — user-visible AND fed to Claude
  m=$(esc "$1")
  emit "{\"systemMessage\":\"$m\",\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$m\"}}"
}

bytes=$(wc -c < "$out" 2>/dev/null | tr -d ' ')
[ "$bytes" = 0 ] && warn "imagemagick: $base is 0 bytes — the write may have failed."

info=$(magick identify -format '%m %wx%h %z-bit %[colorspace]\n' "$out" 2>/dev/null | head -1)
[ -n "$info" ] || warn "imagemagick: $base is not a decodable image (identify failed)."

size=$(du -h "$out" 2>/dev/null | cut -f1)
note=$(esc "imagemagick sanity check — wrote $base: $info, $size")
emit "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$note\"}}"
