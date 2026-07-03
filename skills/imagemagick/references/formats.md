# Format-specific knowledge

Encoder details and format selection. All verified against IM 7.1.2 (libwebp 1.6.0,
libheif 1.23.0, libjxl 0.11.2, libtiff 4.7.1). Support varies by build — check with
`magick -list format | grep -i <fmt>` (`rw+` = read/write/multi-image).

## Choosing a format

| Content | Reach for | Notes |
|---|---|---|
| Photos on the web | WebP (`-quality 80`) or AVIF (`-quality 55`) | AVIF smaller, slower to encode |
| Screenshots / UI / line art | PNG, or lossless WebP | JPEG smears hard edges |
| Needs alpha + small | WebP or AVIF | JPEG cannot store alpha |
| Animation | GIF (compat) / animated WebP (size) | video → GIF is ffmpeg's job |
| Print / archival masters | TIFF (`-compress Zip`) or PNG | lossless, widely accepted |
| Favicons | ICO (multi-resolution, below) | |

## PNG

An output prefix forces the PNG subtype (extension alone lets the encoder choose):

```sh
magick in.png png8:out.png     # 8-bit palette (≤256 colors) + binary transparency — small
magick in.png png24:out.png    # truecolor, opaque or binary transparency only
magick in.png png32:out.png    # truecolor + full 8-bit alpha, forced even if opaque
```

- `png8:` quantizes — combine with dithering control from `color.md` for quality.
- `-define png:compression-level=9` (0–9) trades CPU for size; PNG stays lossless.
- Check what you produced: `magick identify -format '%[type] %[bit-depth]-bit\n' out.png`
  (`Palette`, `TrueColor`, `TrueColorAlpha`…).

## WebP

```sh
magick in.png -quality 80 out.webp                    # lossy; 75–85 is the sweet spot
magick in.png -define webp:lossless=true out.webp     # lossless mode — ignores -quality
```

Alpha is preserved in both modes. Animated WebP from frames works like GIF:
`magick -delay 10 -loop 0 frame_*.png anim.webp`.

## AVIF / HEIC

Both go through libheif; both keep alpha and ICC profiles.

```sh
magick in.png -quality 55 out.avif                          # AVIF: quality 50–60 ≈ JPEG 80
magick in.png -quality 55 -define heic:speed=8 out.avif     # speed 0(best)–9(fastest); AVIF only
magick in.png -quality 55 out.heic                          # HEIC (HEVC codec)
magick in.png -define heic:lossless=true out.avif           # lossless (both formats)
```

- Encoding large images at default speed is **slow** (seconds to minutes); raise
  `heic:speed` for AVIF batches.
- `heic:speed` is rejected by the HEVC encoder in some builds
  (`Unsupported encoder parameter`) — omit it for `.heic` outputs.
- iPhone HEICs carry EXIF orientation: add `-auto-orient` when converting them out,
  or portraits arrive sideways.

## JPEG XL

Modern builds include libjxl:

```sh
magick in.png -quality 90 out.jxl                     # lossy
magick in.png -quality 100 out.jxl                    # quality 100 = mathematically lossless
magick in.jpg out.jxl                                 # from JPEG: near-lossless recompression
```

`-define jxl:effort=7` (1–9) trades encode time for density.

## ICO (favicons)

One command emits a real multi-resolution icon:

```sh
magick logo.png -define icon:auto-resize=16,32,48,256 favicon.ico
```

Verify the entries: `magick identify favicon.ico` lists one line per size. The 256px
entry dominates file size — drop it from the list if the icon is only for browser tabs.

## TIFF

```sh
magick in.png -compress Zip out.tif     # lossless; usually smallest lossless choice
magick in.png -compress LZW out.tif     # lossless; legacy-tool compatibility
magick in.png -compress JPEG out.tif    # lossy JPEG-in-TIFF — much smaller, quality applies
magick page1.png page2.png multi.tif    # multipage: all inputs become pages
magick 'multi.tif[1]' page2.png         # read one page back (quote the brackets)
```

Default is **no compression** — a plain `out.tif` is huge; always pick a `-compress`.
Check with `magick identify -format '%f page %s: %C\n' multi.tif`.
