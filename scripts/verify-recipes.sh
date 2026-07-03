#!/usr/bin/env bash
# Smoke test: runs every command documented in skills/imagemagick/ against the
# tiny fixtures in test-images/, in a temp dir, and reports PASS/FAIL/SKIP.
#
# The command list below is hand-maintained and mirrors the docs (filenames
# adapted to the fixtures). It does NOT parse the markdown, so it drifts when
# the docs change: whenever a command is added or edited in SKILL.md or
# references/*.md, update the matching line here. Each section names its
# source file.
#
# Skips (not failures): PDF/PS cases when Ghostscript is absent, AVIF when the
# build lacks the encoder. On this machine run PDF cases via:
#   nix shell nixpkgs#ghostscript --command scripts/verify-recipes.sh

set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$REPO/test-images"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0 FAIL=0 SKIP=0

run() { # run <label> <command...>
  local label="$1"; shift
  local out
  if out="$("$@" 2>&1)"; then
    PASS=$((PASS+1)); printf 'PASS  %s\n' "$label"
  else
    FAIL=$((FAIL+1)); printf 'FAIL  %s\n      %s\n' "$label" "$out"
  fi
}

skip() { SKIP=$((SKIP+1)); printf 'SKIP  %s (%s)\n' "$1" "$2"; }

assert_dims() { # assert_dims <label> <file> <WxH>
  local got
  got="$(magick identify -format '%wx%h' "$2" 2>&1)"
  if [ "$got" = "$3" ]; then
    PASS=$((PASS+1)); printf 'PASS  %s (%s)\n' "$1" "$got"
  else
    FAIL=$((FAIL+1)); printf 'FAIL  %s: expected %s, got %s\n' "$1" "$3" "$got"
  fi
}

cd "$WORK"
cp "$FIX"/tiny.png "$FIX"/tiny.jpg "$FIX"/anim.gif "$FIX"/tiny.svg .

# Larger derived inputs — several documented commands need room to crop/resize.
magick -size 640x480 gradient:skyblue-navy photo.jpg
magick -size 400x300 plasma:fractal in.jpg
magick tiny.png -resize '300x200!' in.png
magick -size 120x60 xc:none -fill white -stroke black \
  -draw 'roundrectangle 5,5 115,55 10,10' logo.png
magick -size 100x100 xc:red frame_001.png
magick -size 100x100 xc:green frame_002.png
printf 'Smoke-test text file.\nSecond line.\n' > notes.txt

HAVE_GS=; command -v gs >/dev/null && HAVE_GS=1
HAVE_AVIF=; magick -list format 2>/dev/null | grep -q '^ *AVIF' && HAVE_AVIF=1
FONT_ARGS=()
magick -list font 2>/dev/null | grep -q 'Font: DejaVu-Serif' && FONT_ARGS=(-font DejaVu-Serif)

echo "== SKILL.md: quick reference"
run "convert format"      magick in.png out.webp
run "resize fit"          magick in.jpg -resize 800x600 s02.jpg
run "thumbnail"           magick in.jpg -thumbnail 200x200 s03.jpg
run "exact fill"          magick in.jpg -resize '800x600^' -gravity center -extent 800x600 s04.jpg
assert_dims "  exact fill is 800x600" s04.jpg 800x600
run "crop +repage"        magick in.png -crop 100x80+50+100 +repage s05.png
assert_dims "  crop is 100x80" s05.png 100x80
run "rotate 90"           magick in.jpg -rotate 90 s06.jpg
run "quality 85"          magick in.png -quality 85 s07.jpg
run "strip metadata"      magick in.jpg -strip s08.jpg
run "flatten onto white"  magick in.png -background white -flatten s09.jpg
run "gif from frames"     magick -delay 10 -loop 0 frame_001.png frame_002.png s10.gif
run "montage"             magick montage in.jpg photo.jpg -tile 4x -geometry +5+5 s11.png
# compare exits 1 when images differ — only 2 is an error (documented pitfall)
magick compare -metric RMSE frame_001.png frame_002.png s12.png >/dev/null 2>&1
case $? in
  0|1) PASS=$((PASS+1)); echo "PASS  compare exit 0/1" ;;
  *)   FAIL=$((FAIL+1)); echo "FAIL  compare exited >1" ;;
esac
run "frame index syntax"  magick 'anim.gif[0]' s13.png

echo "== SKILL.md: batch + pitfalls"
mkdir -p out resized
run "mogrify -path"       magick mogrify -path out/ -resize 50% in.jpg photo.jpg
run "shell loop"          bash -c 'for f in frame_*.png; do magick "$f" -resize 1200x "resized/${f%.png}.jpg"; done'
run "resource limits"     magick in.jpg -limit memory 2GiB -limit disk 4GiB -resize 50% s14.jpg
run "list resource"       magick identify -list resource
run "clamp"               magick in.png -clamp s15.png

echo "== references/geometry.md"
for g in '800x600' '800x600!' '800x600^' '800x600>' '800x600<' '800x' 'x600' '50%' '50x25%' '64000@'; do
  run "resize '$g'"       magick photo.jpg -resize "$g" "geo$PASS.png"
done
run "cover crop"          magick in.jpg -resize '800x600^' -gravity center -extent 800x600 g01.jpg
run "letterbox"           magick in.jpg -resize 800x600 -background black -gravity center -extent 800x600 g02.jpg
run "square thumbnail"    magick in.jpg -thumbnail '200x200^' -gravity center -extent 200x200 g03.jpg
assert_dims "  square thumb is 200x200" g03.jpg 200x200
run "pixel-art sample"    magick frame_001.png -sample 400% g04.png
run "liquid-rescale"      magick in.jpg -liquid-rescale 50% g05.jpg

echo "== references/recipes.md"
run "logo watermark"      magick photo.jpg \( logo.png -alpha set -channel A -evaluate multiply 0.5 +channel \) -gravity southeast -geometry +10+10 -composite r01.jpg
run "tiled text watermark" magick photo.jpg \( -size 280x160 xc:none -fill 'rgba(255,255,255,0.25)' -pointsize 28 -gravity center -annotate 315 'CONFIDENTIAL' -write mpr:tile +delete photo.jpg -tile mpr:tile -draw 'color 0,0 reset' \) -composite r02.jpg
run "caption bar"         magick photo.jpg -background '#222' -fill white -pointsize 24 label:'A caption' -gravity center -append r03.jpg
run "annotate title"      magick photo.jpg -fill yellow -stroke black -strokewidth 1 -pointsize 48 -gravity north -annotate +0+20 'Title' r04.jpg
run "jpeg web-optimize"   magick in.jpg -strip -interlace Plane -sampling-factor 4:2:0 -quality 85 r05.jpg
run "png to webp"         magick in.png -quality 80 r06.webp
if [ -n "$HAVE_AVIF" ]; then
  run "png to avif"       magick in.png -quality 60 r07.avif
else
  skip "png to avif" "no AVIF encoder in this build"
fi
run "srcset resize"       magick photo.jpg -resize 480x -quality 82 r08-480w.jpg
if [ -n "$HAVE_GS" ]; then
  magick -size 200x100 xc:white -fill black -pointsize 20 -annotate +20+50 'PDF page' doc.pdf
  run "pdf rasterize"     magick -density 300 'doc.pdf[0]' -background white -flatten r09.png
else
  skip "pdf rasterize" "Ghostscript not installed"
fi
run "svg rasterize 2x"    magick -density 192 -background none tiny.svg r10.png
run "gif optimize"        magick anim.gif -coalesce -layers optimize r11.gif
run "gif extract frames"  magick anim.gif -coalesce r12_%03d.png
run "auto-level"          magick in.jpg -auto-level r13.jpg
run "modulate"            magick in.jpg -modulate 100,130,100 r14.jpg
run "grayscale"           magick in.jpg -colorspace Gray r15.jpg
run "sepia"               magick in.jpg -sepia-tone 80% r16.jpg
run "white to transparent" magick in.png -fuzz 10% -transparent white r17.png
run "level"               magick in.jpg -level 5%,95%,1.2 r18.jpg
run "identify -verbose"   magick identify -verbose in.jpg
run "identify -format"    magick identify -format '%wx%h %[colorspace] %[bit-depth]-bit alpha:%A\n' in.png
run "exif dump"           magick in.jpg -format '%[EXIF:*]' info:

echo "== references/generative.md"
run "xc solid"            magick -size 800x600 xc:'#204060' c01.png
run "linear gradient"     magick -size 800x600 gradient:orange-purple c02.png
run "radial gradient"     magick -size 800x600 radial-gradient:white-black c03.png
run "plasma"              magick -size 800x600 plasma:fractal c04.png
run "noise"               magick -size 800x600 xc: +noise Random c05.png
run "checkerboard"        magick -size 100x100 pattern:checkerboard -scale 800x800 c06.png
run "sinusoid"            magick -size 800x600 gradient: -function Sinusoid 4,90 c07.png
run "list gradient"       magick -list gradient
run "text: typeset"       magick -density 120 'text:notes.txt[0]' t01.png
run "label auto-size"     magick -background none -fill white -pointsize 64 label:'Hello' t02.png
run "caption word-wrap"   magick -size 500x -background '#fffef0' -fill '#333' "${FONT_ARGS[@]}" caption:@notes.txt t03.png
if [ -n "$HAVE_GS" ]; then
  magick -size 200x100 xc:white doc.ps
  run "ps rasterize"      magick -density 150 'doc.ps[0]' -background white -flatten t04.png
else
  skip "ps rasterize" "Ghostscript not installed"
fi
run "drop shadow"         magick t02.png \( +clone -background black -shadow 50x9+12+16 \) +swap -background white -layers merge +repage e01.png
run "polaroid"            magick photo.jpg -bordercolor snow -background black +polaroid e02.png
run "vignette"            magick photo.jpg \( +clone -fill black -colorize 100 -fill white -draw 'circle 320,240 320,50' -blur 0x40 \) -compose multiply -composite e03.jpg
run "torn edges"          magick photo.jpg \( +clone -threshold 50% -spread 8 -blur 0x1 \) -alpha off -compose copy_opacity -composite e04.png
run "perspective"         magick t02.png -virtual-pixel transparent -background none -distort Perspective '0,0 30,10  200,0 185,5  0,80 10,70  200,80 195,55' d01.png
run "arc"                 magick in.png -distort Arc 60 d02.png
run "barrel"              magick in.png -distort Barrel '0.0 0.0 0.05' d03.png
run "wave"                magick in.png -wave 12x200 d04.png
run "implode"             magick in.png -implode 0.4 d05.png
run "shepards"            magick in.png -distort Shepards '200,100 250,100' d06.png

echo "== scripts/fold-paper.sh"
run "fold-paper.sh"       "$REPO/skills/imagemagick/scripts/fold-paper.sh" notes.txt folded.png

echo
echo "$PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ]
