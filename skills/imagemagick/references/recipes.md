# Recipes

Multi-step patterns for common requests. All syntax is ImageMagick 7 (`magick`).

## Watermark / logo overlay

```sh
# Bottom-right, 10px inset, 50% opacity
magick photo.jpg \( logo.png -alpha set -channel A -evaluate multiply 0.5 +channel \) \
  -gravity southeast -geometry +10+10 -composite out.jpg

# Tiled text watermark across the whole image
magick photo.jpg \( -size 280x160 xc:none -fill 'rgba(255,255,255,0.25)' \
  -pointsize 28 -gravity center -annotate 315 'CONFIDENTIAL' -write mpr:tile +delete \
  photo.jpg -tile mpr:tile -draw 'color 0,0 reset' \) -composite out.jpg
```

Parentheses `\( ... \)` process a sub-image on its own stack without affecting the main image. They must be escaped and space-separated in the shell.

## Text annotation

```sh
# Caption bar under the image
magick photo.jpg -background '#222' -fill white -pointsize 24 \
  label:'A caption' -gravity center -append out.jpg

# Text drawn onto the image at a position
magick photo.jpg -fill yellow -stroke black -strokewidth 1 -pointsize 48 \
  -gravity north -annotate +0+20 'Title' out.jpg
```

`label:` auto-sizes the canvas to the text; `caption:` word-wraps within a `-size` box; `-annotate` draws over an existing image. List available fonts with `magick -list font`; use `-font <name>` or a path to a TTF.

## Web optimization

```sh
# JPEG: strip metadata, progressive, chroma subsampling, ~85 quality
magick in.jpg -strip -interlace Plane -sampling-factor 4:2:0 -quality 85 out.jpg

# PNG → lossy WebP (much smaller)
magick in.png -quality 80 out.webp

# AVIF (smaller still; slower to encode)
magick in.png -quality 60 out.avif

# Resize + srcset set
for w in 480 800 1200 1600; do magick hero.jpg -resize ${w}x -quality 82 hero-${w}w.jpg; done
```

## PDF and vector input

```sh
# Rasterize a PDF page at print resolution (density BEFORE input)
magick -density 300 doc.pdf[0] -background white -flatten page1.png

# SVG at 2x — with the common librsvg delegate, SVG pixels are CSS pixels
# (96/inch), so scale = density/96, not density/72. Verify the output size.
magick -density 192 -background none icon.svg icon.png
```

Two distinct PDF failure modes: `FailedToExecuteCommand ... 'gs'` means Ghostscript is not installed; `not allowed by the security policy` means the system `policy.xml` blocks Ghostscript formats. Report either to the user rather than editing system config unprompted.

## Animated GIF

```sh
# From frames: 10 = 0.10s per frame; -loop 0 = forever
magick -delay 10 -loop 0 frame_*.png anim.gif

# Optimize an existing GIF
magick anim.gif -coalesce -layers optimize opt.gif

# Extract frames
magick anim.gif -coalesce frame_%03d.png

# Video → GIF is ffmpeg's job, not ImageMagick's — suggest ffmpeg for that.
```

`-coalesce` expands frame deltas to full frames; needed before editing GIF frames, and `-layers optimize` re-compacts afterward.

## Color and tone

```sh
magick in.jpg -auto-level out.jpg                 # stretch contrast
magick in.jpg -modulate 100,130,100 out.jpg        # +30% saturation (brightness,saturation,hue)
magick in.jpg -colorspace Gray out.jpg             # grayscale
magick in.jpg -sepia-tone 80% out.jpg
magick in.png -fuzz 10% -transparent white out.png # white → transparent
magick in.jpg -level 5%,95%,1.2 out.jpg            # black point, white point, gamma
```

## Diagnostics

```sh
magick identify -verbose in.jpg                      # everything
magick identify -format '%wx%h %[colorspace] %[bit-depth]-bit alpha:%A\n' in.png
magick in.jpg -format '%[EXIF:*]' info:              # dump EXIF
magick compare -metric SSIM a.png b.png null: 2>&1   # similarity score only
```

`-format`/`-print` percent escapes (`%w`, `%h`, `%[mean]`, …) turn ImageMagick into a scriptable image-inspection tool; full list: https://imagemagick.org/script/escape.php (there is no `-list` type for them — `magick -list list` shows what can be listed). Note `magick compare` exits 1 when images differ; that is a result, not an error.
