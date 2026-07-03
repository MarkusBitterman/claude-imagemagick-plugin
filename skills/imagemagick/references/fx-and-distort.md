# -fx expressions, deep -distort, and morphology

Per-pixel math, geometric warps beyond the basics, and shape operators.
Verified against IM 7.1.2. For the showcase distortions (Perspective, Arc,
Barrel, Shepards) see `generative.md`; this file goes deeper.

## -fx: per-pixel expressions

```sh
magick in.png -fx '(r+g+b)/3' gray.png           # channel math (r,g,b,a in 0..1)
magick in.png -fx 'u>0.5 ? 1 : 0' hard.png       # u = current pixel; ternaries work
magick a.png b.png -fx '(u+v)/2' blend.png       # u = first image, v = second
magick in.png -fx 'p[-1,0]' shifted.png          # p[dx,dy] = relative neighbor access
magick in.png -fx 'luminance' luma.png           # named accessors: luminance, hue, ...
```

Performance: `-fx` is an interpreter. Simple expressions are only mildly slower
than the dedicated operators, but cost scales with expression complexity and
`p[...]` neighbor access can crawl on large images. Prefer the compiled
equivalents when one exists: `-evaluate multiply 0.5`, `-function Polynomial`,
`-compose Mathematics`.

The killer non-obvious use is **`%[fx:...]` escapes** — evaluate once, no pixel
loop, perfect for scripting:

```sh
magick in.png -format '%[fx:mean]' info:                    # 0..1 mean intensity
magick in.png -format '%[fx:standard_deviation]' info:
magick in.png -format '%[fx:w/h]' info:     # aspect ratio; fx is numbers-only — branch in the shell
```

## -distort, beyond the basics

```sh
# SRT = scale-rotate-translate. One number = degrees about the center.
magick in.png -background none -virtual-pixel transparent -distort SRT 30 rot.png
magick in.png -virtual-pixel edge -distort SRT '100,75 0.8 30 100,75' srt.png
                                  # center cx,cy  scale  angle  new center nx,ny

# +distort (plus form) grows the canvas to fit the result instead of clipping
magick in.png -background none -virtual-pixel transparent +distort SRT 30 grown.png

# Affine: pairs of 'from,to' control points define the transform
magick in.png -virtual-pixel white -distort Affine '0,0 0,0  200,0 200,30  0,150 20,150' shear.png

# Polar/DePolar: unwrap to polar coordinates and back (0 = auto radius)
magick in.png -distort DePolar 0 unwrapped.png    # edit stripes, then re-wrap:
magick unwrapped.png -distort Polar 0 rewrapped.png
```

- Always set `-virtual-pixel` (and `-background` for `transparent`) *before* the
  distort — it controls what fills exposed areas: `edge`, `mirror`, `tile`,
  `transparent`, `white`…
- **Displacement maps are a compose method, not a distort.** Gray map, 50% = no
  shift; `15x15` = max shift in pixels:

```sh
magick photo.png \( -size 200x150 plasma: -blur 0x4 \) \
  -compose displace -set option:compose:args 15x15 -composite rippled.png
```

## Morphology

Shape-based operators on (usually binary) images. `Kernel:size` syntax:

```sh
magick mask.png -morphology Erode  Octagon:3 out.png   # shrink shapes 3px
magick mask.png -morphology Dilate Octagon:3 out.png   # grow shapes 3px
magick mask.png -morphology Open   Disk out.png        # erode+dilate: removes specks
magick mask.png -morphology Close  Disk out.png        # dilate+erode: fills pinholes
magick mask.png -morphology EdgeIn Diamond out.png     # outline just inside shapes
```

Open/Close are the practical pair: `Open` denoises a thresholded scan, `Close`
heals gaps before tracing. `magick -list kernel` shows built-in kernels;
`magick -list morphology` the methods.

Convolution rides the same operator — built-in or hand-rolled kernels:

```sh
magick in.png -morphology Convolve Laplacian:0 edges.png
magick in.png -morphology Convolve '3x3: 0,1,0 1,-4,1 0,1,0' edges.png  # same, explicit
```

## Also see

Anthony Thyssen's chapters are the canonical deep dives:
https://imagemagick.org/Usage/transform/ (fx), /distorts/, /morphology/
