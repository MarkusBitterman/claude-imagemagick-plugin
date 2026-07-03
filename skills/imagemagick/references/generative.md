# Generative ImageMagick — images from nothing

ImageMagick is not just a converter; it is a graphical editor for shell geeks
who don't need the graphical part. Pages can be typeset, canvases synthesized,
and effects layered entirely from the command line. Reach for this reference
when the user wants to *create* or *stylize*, not merely transform.

## Canvases from nothing

```sh
magick -size 800x600 xc:'#204060' solid.png                 # solid color
magick -size 800x600 gradient:orange-purple grad.png        # linear gradient
magick -size 800x600 radial-gradient:white-black rad.png
magick -size 800x600 plasma:fractal plasma.png              # fractal clouds
magick -size 800x600 xc: +noise Random noise.png
magick -size 100x100 pattern:checkerboard -scale 800x800 checks.png
magick -size 800x600 gradient: -function Sinusoid 4,90 waves.png
```

`magick -list gradient` shows the gradient types; there is no `-list pattern` —
built-in patterns are enumerated at https://imagemagick.org/script/formats.php
(pseudo-formats). Combine with `-compose`/`-fx` for procedural textures. To draw
shapes, paths, and text *onto* these canvases, see `drawing.md`.

## Typesetting text and documents

```sh
# Plain .txt → paginated letter-size pages (built-in text delegate)
magick -density 120 'text:notes.txt[0]' page.png    # QUOTE the [0] — shells glob brackets

# Auto-sized one-liner
magick -background none -fill white -pointsize 64 label:'Hello' hello.png

# Word-wrapped paragraph in a fixed-width box
magick -size 500x -background '#fffef0' -fill '#333' -font DejaVu-Serif \
  caption:@essay.txt card.png                        # @file reads text from a file

# PostScript/PDF → PNG (needs Ghostscript; -density before input)
magick -density 150 'doc.ps[0]' -background white -flatten page.png
```

## Effects that sell realism

```sh
# Drop shadow: clone → shadow → merge (the canonical stanza)
magick page.png \( +clone -background black -shadow 50x9+12+16 \) +swap \
  -background white -layers merge +repage shadowed.png

# Polaroid: rotate, border, and shadow in one operator
magick photo.jpg -bordercolor snow -background black +polaroid polaroid.png

# Vignette
magick photo.jpg \( +clone -fill black -colorize 100 -fill white \
  -draw 'circle 400,300 400,50' -blur 0x40 \) -compose multiply -composite out.jpg

# Torn/rough edges
magick photo.jpg \( +clone -threshold 50% -spread 8 -blur 0x1 \) \
  -alpha off -compose copy_opacity -composite torn.png
```

## Warps and distortions

```sh
magick page.png -virtual-pixel transparent -background none \
  -distort Perspective '0,0 30,10  W,0 W-15,5  0,H 10,H-10  W,H W-5,H-25' tilted.png
magick in.png -distort Arc 60 arced.png                # bend around a circle
magick in.png -distort Barrel '0.0 0.0 0.05' bulge.png # lens bulge
magick in.png -wave 12x200 wavy.png                    # sine-wave ripple
magick in.png -implode 0.4 pinched.png
magick in.png -distort Shepards '200,200 250,200' local-warp.png  # move points, rest follows
```

In `-distort Perspective`, substitute real pixel coordinates for `W`/`H`
(compute them with `magick identify -format %w/%h`). Set `-virtual-pixel`
*before* the distort or the exposed edges fill with garbage. For SRT/Affine/
Polar distorts, displacement maps, `-fx`, and morphology, see `fx-and-distort.md`.

## Worked example: .txt → folded letter photo

`scripts/fold-paper.sh` in this skill runs the full classic pipeline —
typeset (`text:`), tri-fold lighting (stacked `gradient:` strips,
`-compose multiply`), crease lines (`-draw line` dark+light pairs),
perspective warp, drop shadow:

```sh
skills/imagemagick/scripts/fold-paper.sh notes.txt folded.png
```

Use it as a template: every stage is an independent, inspectable intermediate.
The composition pattern — *build lighting/masks as separate synthesized images,
then multiply/screen/copy_opacity them onto the subject* — generalizes to most
"make it look physical" requests.

## Also see

Fred Weinhaus maintains ~380 ready-made effect scripts (page curl, texture,
weave, emboss, kaleidoscope…): https://www.fmwconcepts.com/imagemagick/index.php
— non-commercial license; adapt techniques, don't vendor the scripts.
Anthony Thyssen's examples are the canonical deep dive: https://imagemagick.org/Usage/
