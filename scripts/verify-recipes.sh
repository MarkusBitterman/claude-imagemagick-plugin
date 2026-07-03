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
HAVE_HEIC=; magick -list format 2>/dev/null | grep -q '^ *HEIC.*rw' && HAVE_HEIC=1
HAVE_JXL=;  magick -list format 2>/dev/null | grep -q '^ *JXL' && HAVE_JXL=1
# any ICC profile file on the system enables the profile assign/convert cases
ICC_FILE=$(ls /usr/share/color/icc/*.icc /usr/share/color/icc/*/*.icc \
  /nix/store/*colord*/share/color/icc/colord/sRGB.icc 2>/dev/null | head -1 || true)
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

echo "== references/formats.md"
run "png8: prefix"        magick in.png png8:fm01.png
run "png32: prefix"       magick in.png png32:fm02.png
run "png compression"     magick in.png -define png:compression-level=9 fm03.png
run "webp lossless"       magick in.png -define webp:lossless=true fm04.webp
run "animated webp"       magick -delay 10 -loop 0 frame_001.png frame_002.png fm05.webp
if [ -n "$HAVE_AVIF" ]; then
  run "avif speed"        magick in.png -quality 55 -define heic:speed=8 fm06.avif
  run "avif lossless"     magick tiny.png -define heic:lossless=true fm07.avif
else
  skip "avif speed/lossless" "no AVIF encoder"
fi
if [ -n "$HAVE_HEIC" ]; then
  run "heic write"        magick in.png -quality 55 fm08.heic
else
  skip "heic write" "no HEIC encoder"
fi
if [ -n "$HAVE_JXL" ]; then
  run "jxl lossy"         magick in.png -quality 90 fm09.jxl
  run "jxl from jpeg"     magick in.jpg fm10.jxl
else
  skip "jxl" "no JXL encoder"
fi
run "ico multi-res"       magick logo.png -define icon:auto-resize=16,32,48 favicon.ico
run "tiff zip"            magick in.png -compress Zip fm11.tif
run "tiff jpeg"           magick in.png -compress JPEG fm12.tif
run "tiff multipage"      magick frame_001.png frame_002.png fm13.tif
run "tiff page read"      magick 'fm13.tif[1]' fm14.png

echo "== references/color.md"
run "linear-light resize" magick in.jpg -colorspace RGB -resize 50% -colorspace sRGB co01.jpg
run "lineargray"          magick in.jpg -colorspace LinearGray co02.jpg
run "colors 16"           magick photo.jpg -colors 16 co03.png
run "no dither"           magick photo.jpg +dither -colors 16 co04.png
run "remap file"          magick photo.jpg -remap co03.png co05.png
run "remap netscape:"     magick photo.jpg -remap netscape: co06.png
run "posterize"           magick photo.jpg -posterize 4 co07.png
run "quantize LAB"        magick photo.jpg -quantize LAB -colors 16 co08.png
run "ordered-dither o8x8" magick photo.jpg -ordered-dither o8x8,8 co09.png
run "ordered halftone"    magick photo.jpg -colorspace Gray -ordered-dither h6x6a co10.png
run "color-matrix"        magick in.jpg -color-matrix '1 0 0 0 1 0 0 0 1.08' co11.jpg
run "normalize"           magick in.jpg -normalize co12.jpg
if [ -n "$ICC_FILE" ]; then
  run "icc assign"        magick photo.jpg -profile "$ICC_FILE" co13.jpg
  run "icc extract"       magick co13.jpg co14.icc
else
  skip "icc assign/extract" "no .icc profile file found on system"
fi

echo "== references/drawing.md"
run "draw line"           magick -size 200x200 xc:white -stroke black -strokewidth 3 -draw 'line 20,20 180,180' dr01.png
run "draw roundrect"      magick -size 200x200 xc:white -fill none -stroke '#333' -strokewidth 4 -draw 'roundrectangle 20,20 180,180 15,15' dr02.png
run "draw circle"         magick -size 200x200 xc:white -fill gold -draw 'circle 100,100 100,40' dr03.png
run "draw ellipse arc"    magick -size 200x200 xc:white -fill none -stroke black -draw 'ellipse 100,100 80,60 45,270' dr04.png
run "draw polygon"        magick -size 200x200 xc:white -fill seagreen -draw 'polygon 100,20 180,180 20,180' dr05.png
run "draw bezier"         magick -size 200x200 xc:white -fill none -stroke purple -strokewidth 3 -draw 'bezier 20,180 60,20 140,20 180,180' dr06.png
run "draw svg path"       magick -size 200x200 xc:white -fill orange -draw "path 'M 100,30 L 170,170 L 30,170 Z'" dr07.png
run "fill-opacity"        magick -size 200x200 xc:white -draw 'fill red fill-opacity 0.4 rectangle 30,30 120,120 fill blue rectangle 80,80 170,170' dr08.png
run "gravity draw text"   magick -size 200x100 xc:'#eee' -pointsize 20 -fill '#333' -gravity center -draw "text 0,0 'centered'" dr09.png
run "push/pop rotate"     magick -size 200x200 xc:white -fill none -stroke black -draw 'push graphic-context translate 100,100 rotate 30 rectangle -60,-25 60,25 pop graphic-context' dr10.png
run "image in draw"       magick -size 200x200 xc:'#ddd' -draw 'image over 40,40 64,64 "logo.png"' dr11.png
run "placeholder"         magick -size 640x360 xc:'#dee2e6' -fill '#6c757d' -pointsize 48 -gravity center -annotate +0+0 '640x360' dr12.png

echo "== references/fx-and-distort.md"
run "fx average"          magick tiny.png -fx '(r+g+b)/3' fx01.png
run "fx ternary"          magick tiny.png -fx 'u>0.5 ? 1 : 0' fx02.png
run "fx two-image"        magick frame_001.png frame_002.png -fx '(u+v)/2' fx03.png
run "fx neighbor"         magick tiny.png -fx 'p[-1,0]' fx04.png
run "fx escape mean"      magick identify -format '%[fx:mean]' tiny.png
run "fx escape aspect"    magick identify -format '%[fx:w/h]' tiny.png
run "evaluate multiply"   magick tiny.png -evaluate multiply 0.5 fx05.png
run "distort SRT"         magick in.png -background none -virtual-pixel transparent -distort SRT 30 fx06.png
run "distort SRT full"    magick in.png -virtual-pixel edge -distort SRT '100,75 0.8 30 100,75' fx07.png
run "+distort grows"      magick in.png -background none -virtual-pixel transparent +distort SRT 30 fx08.png
run "distort Affine"      magick in.png -virtual-pixel white -distort Affine '0,0 0,0  200,0 200,30  0,150 20,150' fx09.png
run "depolar/polar"       bash -c "magick in.png -distort DePolar 0 fx10.png && magick fx10.png -distort Polar 0 fx11.png"
run "compose displace"    magick in.png \( -size 300x200 plasma: -blur 0x4 \) -compose displace -set option:compose:args 15x15 -composite fx12.png
magick -size 200x200 xc:black -fill white -draw 'circle 100,100 100,55' morphshape.png
run "morphology erode"    magick morphshape.png -morphology Erode Octagon:3 fx13.png
run "morphology open"     magick morphshape.png -morphology Open Disk fx14.png
run "morphology edgein"   magick morphshape.png -morphology EdgeIn Diamond fx15.png
run "convolve laplacian"  magick tiny.png -morphology Convolve Laplacian:0 fx16.png
run "custom kernel"       magick tiny.png -morphology Convolve '3x3: 0,1,0 1,-4,1 0,1,0' fx17.png

echo "== scripts/fold-paper.sh"
run "fold-paper.sh"       "$REPO/skills/imagemagick/scripts/fold-paper.sh" notes.txt folded.png

echo
echo "$PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ]
