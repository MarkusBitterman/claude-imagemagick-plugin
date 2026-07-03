---
name: imagemagick
description: This skill should be used when the user asks to "resize an image", "convert an image" (PNG/JPEG/WebP/AVIF/HEIC/GIF/TIFF/etc.), "crop", "compress", "optimize", "composite", "watermark", "annotate", "montage", "make a thumbnail", "strip metadata", "batch process images", "make an animated GIF", "generate an image", "add a drop shadow", "make a placeholder/test image", "render text as an image", "make it look like paper/polaroid/folded", "make a favicon", "reduce the number of colors", "fix washed-out colors", "convert a color profile (ICC)", "dither an image", "draw shapes/lines on an image", "apply a displacement or warp", or otherwise manipulate, inspect, or generate raster images from the command line with ImageMagick or GraphicsMagick.
version: 0.3.0
---

# ImageMagick

Guidance for performing image operations with the ImageMagick command-line tools.

## First steps

1. Confirm the toolchain: `magick -version` (ImageMagick 7). If only `convert`/`identify` exist without `magick`, it is ImageMagick 6; if only `gm` exists, it is GraphicsMagick. See `references/gm-and-im6.md` for syntax differences.
2. Inspect before you transform: `magick identify <file>` for a one-liner, `magick identify -verbose <file>` for full detail (color profile, alpha, EXIF, quality estimate).
3. Never overwrite the user's originals unless explicitly asked. Write outputs to new filenames or a separate directory.

## IM7 command model

```
magick [input-settings] input.img [operators] output.img
```

- **`magick` replaces `convert`.** The bare `convert` still works in IM7 but is deprecated (and on Windows collides with a system tool). Prefer `magick`.
- **Order matters.** *Settings* (e.g. `-quality`, `-density`, `-background`) persist and affect later operations; *operators* (e.g. `-resize`, `-crop`, `-rotate`) act immediately on the images currently in the stack. Settings placed *before* an input affect reading (`-density 300 input.pdf`); operators placed *after* affect the loaded image.
- The output file is always the **last argument**. Its extension selects the encoder; force one explicitly with a prefix: `png32:out.png`, `jpeg:out.img`.
- Read a specific frame/page with index syntax: `input.gif[0]`, `document.pdf[0-2]` — quote these in the shell; brackets glob in zsh/bash.

## Core operations quick reference

| Task | Command |
|---|---|
| Convert format | `magick in.png out.webp` |
| Resize to fit within box | `magick in.jpg -resize 800x600 out.jpg` |
| Thumbnail (strips metadata, fast) | `magick in.jpg -thumbnail 200x200 out.jpg` |
| Exact size, cropped to fill | `magick in.jpg -resize 800x600^ -gravity center -extent 800x600 out.jpg` |
| Crop region | `magick in.png -crop 400x300+50+100 +repage out.png` |
| Rotate | `magick in.jpg -rotate 90 out.jpg` |
| JPEG quality/size tradeoff | `magick in.png -quality 85 out.jpg` |
| Strip EXIF/metadata | `magick in.jpg -strip out.jpg` |
| Flatten transparency onto color | `magick in.png -background white -flatten out.jpg` |
| Animated GIF from frames | `magick -delay 10 -loop 0 frame*.png out.gif` |
| Contact sheet | `magick montage *.jpg -tile 4x -geometry +5+5 sheet.png` |
| Compare two images | `magick compare -metric RMSE a.png b.png diff.png` |

Geometry syntax (`800x600`, `^`, `!`, `>`, `<`, `%`) is subtle — see `references/geometry.md`. Multi-step recipes (watermarking, PDF rasterization, batch patterns) are in `references/recipes.md`. For *creating* images from nothing — synthesized canvases, typesetting text files, shadows/polaroids/vignettes — see `references/generative.md` and the worked `scripts/fold-paper.sh` example. Encoder specifics (PNG8/32, WebP/AVIF/HEIC/JXL options, multi-res ICO, TIFF compression) are in `references/formats.md`; colorspaces, ICC profiles, palettes and dithering in `references/color.md`; the `-draw` vector language in `references/drawing.md`; `-fx` math, deep `-distort`, and morphology in `references/fx-and-distort.md`.

## Batch processing

- `mogrify` edits **in place** and is the most common way users destroy originals. Always use `-path` to redirect output: `magick mogrify -path out/ -resize 50% *.jpg` (create `out/` first).
- For anything nontrivial, prefer an explicit shell loop with `magick` — it is easier to verify and interrupt. `magick` does not create output directories; make them first:
  ```sh
  mkdir -p resized
  for f in *.png; do magick "$f" -resize 1200x "resized/${f%.png}.jpg"; done
  ```

## Pitfalls

- `-resize 800x600` fits *within* the box preserving aspect ratio; it does **not** produce exactly 800×600. Use `^` + `-extent` for exact fill, or `!` to force distortion.
- After `-crop`, the image keeps its virtual canvas offset; add `+repage` or later operations behave strangely.
- PDF/SVG input rasterizes at 72 DPI by default — set `-density 300` *before* the input filename for usable resolution. PDF support requires Ghostscript and may be blocked by the system `policy.xml`.
- Converting to JPEG silently drops the alpha channel (usually onto black). Flatten onto an explicit `-background` first.
- `magick compare` exits **1 when the images differ** (0 = identical, 2 = error). That nonzero exit is normal output, but it aborts scripts running under `set -e` — append `|| true` or check for exit 2 specifically.
- Very large images can exhaust memory; check/raise limits with `-limit memory 2GiB -limit disk 4GiB` or inspect `magick identify -list resource`.
- HDRI builds (`Q16-HDRI` in `-version`) allow out-of-range pixel values; add `-clamp` before writing if results look blown out after arithmetic operations.
