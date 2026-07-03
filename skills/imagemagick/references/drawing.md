# The -draw language

Vector primitives rendered onto any image or canvas. Verified against IM 7.1.2.
For synthesizing the canvas itself (`xc:`, `gradient:`, `plasma:`) see
`generative.md`; this file covers what you draw *onto* it.

Settings placed before `-draw` (`-fill`, `-stroke`, `-strokewidth`, `-font`,
`-pointsize`, `-gravity`) style everything that follows; they can also be set
*inside* the draw string (`fill red stroke black ...`), which keeps one `-draw`
self-contained.

## Primitives

```sh
magick -size 200x200 xc:white -stroke black -strokewidth 3 \
  -draw 'line 20,20 180,180' out.png

-draw 'rectangle 30,30 170,120'              # two corners
-draw 'roundrectangle 20,20 180,180 15,15'   # + corner radii wx,wy
-draw 'circle 100,100 100,40'                # center, then any point ON the circle
-draw 'ellipse 100,100 80,40 0,360'          # center, radii, arc start,end degrees
-draw 'ellipse 100,100 80,60 45,270'         # partial arc: degrees 45..270
-draw 'polygon 100,20 180,180 20,180'        # auto-closes
-draw 'polyline 20,180 60,60 100,140'        # open path
-draw 'bezier 20,180 60,20 140,20 180,180'   # cubic: start, 2 controls, end
```

Gotcha: `circle` takes center + *perimeter point*, not center + radius.
`-fill none` gives outline-only shapes; `-fill` with no `-stroke` gives borderless fills.

## SVG paths

The full SVG path mini-language works — the escape hatch for anything the
primitives can't express:

```sh
magick -size 200x200 xc:white -fill orange \
  -draw "path 'M 100,30 L 170,170 L 30,170 Z'" triangle.png
```

## In-string state and transforms

```sh
# fill-opacity + overlapping shapes
-draw 'fill red fill-opacity 0.4 rectangle 30,30 120,120 fill blue rectangle 80,80 170,170'

# rotate a shape about its center: translate first, draw around 0,0, then pop
-draw 'push graphic-context translate 100,100 rotate 30 rectangle -60,-25 60,25 pop graphic-context'
```

`push graphic-context` … `pop graphic-context` scopes transforms and style
changes; after the pop, later primitives draw untransformed.

## Text and images inside draw

```sh
# gravity-relative text (offsets measured from the gravity corner/center)
magick -size 200x100 xc:'#eee' -pointsize 20 -fill '#333' -gravity center \
  -draw "text 0,0 'centered'" out.png

# composite another image at a position; w,h of 0,0 = natural size
-draw 'image over 40,40 0,0 "logo.png"'
-draw 'image over 40,40 64,64 "logo.png"'    # resized to 64x64 on the fly
```

`image` supports the compose methods (`over`, `multiply`, `screen`, …). For
single overlays `-composite` (see `recipes.md`) is equivalent; `image` wins when
placing many stamps in one pass.

## Worked example: placeholder image

The placehold.co look, one command:

```sh
magick -size 640x360 xc:'#dee2e6' -fill '#6c757d' -pointsize 48 \
  -gravity center -annotate +0+0 '640x360' placeholder.png
```

Loop it for a set: `for s in 640x360 800x400 1200x630; do magick -size $s ... ; done`
(swap `-annotate +0+0 "$s"` in). Add `-font` from `magick -list font` for brand type;
see `color.md` to hold placeholders to a strict palette.
