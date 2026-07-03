# Color management

Colorspaces, ICC profiles, and palette work. Verified against IM 7.1.2.

## The sRGB vs linear trap

In IM7's naming, **`sRGB` is what image files actually contain** (gamma-encoded);
**`RGB` means linear light**. `-colorspace` converts pixel values, so
`-colorspace RGB` on a normal photo linearizes it (mid-gray 128 becomes ~22%).

That conversion is also the *correct* space for resampling math. Filters average
pixels; averaging gamma-encoded values darkens blends. For quality-critical
downsizing:

```sh
magick in.jpg -colorspace RGB -resize 50% -colorspace sRGB out.jpg
```

The difference is subtle on photos and dramatic on synthetic edges (red/green
checkerboards, star fields). Plain `-resize` in sRGB is fine for everyday work.

Grayscale (verified): `-colorspace Gray` keeps sRGB gamma and weights by Rec.709
luma — pure red lands at 21.3% gray. `-colorspace LinearGray` linearizes; images
converted with it look correct only in linear pipelines, dark elsewhere.

## ICC profiles

The `-profile` operator has two behaviors — this is the classic trap:

- **Image has no profile:** `-profile sRGB.icc` *assigns* — tags the file, pixels
  untouched.
- **Image already has a profile:** `-profile target.icc` *converts* — pixels are
  transformed from the embedded profile to the target, and the target is embedded.

```sh
magick identify -format '%[profile:icc]\n' in.jpg   # what's embedded? (warns "unknown
                                                    # image property" if none)
magick in.jpg out.icc                               # extract the embedded profile to a file
magick photo.jpg -profile sRGB.icc web.jpg          # assign or convert per the rule above
magick cmyk-print.tif -profile sRGB.icc web.jpg     # typical CMYK→sRGB for web
```

- **`-strip` deletes the ICC profile** along with EXIF. A wide-gamut (Display P3,
  Adobe RGB) image stripped to save bytes will render visibly desaturated in
  browsers — convert to sRGB *first*, then strip.
- No profile files on the system? They ship with `colord` (Linux) and most OS
  installs; any sRGB profile works — sRGB is sRGB.

## Palette reduction

```sh
magick in.png -colors 16 out.png              # quantize to ≤16 colors (dithers by default)
magick in.png +dither -colors 16 out.png      # flat posterized look, no dither noise
magick in.png -remap palette.png out.png      # force the palette of another image
magick in.png -remap netscape: out.png        # built-in 216-color web-safe palette
magick in.png -posterize 4 out.png            # 4 levels per channel (≠ 4 colors)
```

- Count what you got: `magick identify -format '%k\n' out.png`.
- `-quantize LAB -colors 16` picks the palette in a perceptual colorspace — often
  better for photos.
- For small GIFs/PNG8, pair `-colors` with the `png8:` prefix from `formats.md`.

## Dithering

`-dither FloydSteinberg` (default) and `-dither Riemersma` apply to quantization
(`-colors`, `-remap`); `+dither` disables. Ordered dithering is a separate operator
with a deliberate halftone look:

```sh
magick in.png -ordered-dither o8x8 out.png     # classic ordered pattern (per channel,
                                               # to black/white per channel)
magick in.png -ordered-dither o8x8,8 out.png   # 8 levels per channel — retro/posterized
magick in.png -colorspace Gray -ordered-dither h6x6a out.png   # halftone-style grayscale
```

`magick -list threshold` shows all ordered-dither maps (checks, halftones, circles).

## Quick fixes

```sh
magick washed.jpg -auto-level out.jpg          # stretch channels to full range
magick dull.jpg -modulate 100,125,100 out.jpg  # +25% saturation
magick warm.jpg -color-matrix '1 0 0 0 1 0 0 0 1.08' out.jpg  # nudge blue channel up 8%
magick photo.jpg -normalize out.jpg            # auto-level with 2% clipping — punchier
```
