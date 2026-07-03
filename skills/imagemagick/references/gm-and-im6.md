# GraphicsMagick and ImageMagick 6 compatibility

Use this reference when the target system lacks the `magick` binary.

## Detecting what's installed

```sh
magick -version        # ImageMagick 7
convert -version       # IM6 if it says "ImageMagick 6.x"; also present (deprecated) in IM7
gm version             # GraphicsMagick
```

Beware: on some systems `convert` is GraphicsMagick's compatibility shim or Windows' NTFS tool. Always check `-version` output before assuming.

## ImageMagick 6 → 7 mapping

| IM6 | IM7 |
|---|---|
| `convert in.png out.jpg` | `magick in.png out.jpg` |
| `identify in.png` | `magick identify in.png` |
| `mogrify -resize 50% *.jpg` | `magick mogrify -resize 50% *.jpg` |
| `composite overlay.png base.png out.png` | `magick base.png overlay.png -composite out.png` |
| `montage *.jpg sheet.png` | `magick montage *.jpg sheet.png` |

Other IM6 quirks: settings/operator ordering is looser (IM6 tolerates misplaced options; IM7 is strict), `-channel` behavior differs subtly, and percent-escape handling was expanded in IM7. When writing for IM6, keep commands simple and explicitly ordered.

## GraphicsMagick

GM is a fork of ImageMagick 5.5 — leaner and faster on basic ops, but missing many IM6/IM7 features. Everything goes through the `gm` multiplexer:

```sh
gm convert in.png -resize 800x600 out.jpg
gm identify -verbose in.png
gm mogrify -output-directory out/ -resize 50% *.jpg   # GM's safer mogrify!
gm montage *.jpg sheet.png
gm composite overlay.png base.png out.png
gm batch commands.txt        # run many ops in one process (GM-only)
```

Notable differences from ImageMagick:

- **No** `-annotate` percent-gravity niceties, no `label:`/`caption:` auto-sizing parity, fewer `-fx`/distortion/morphology operators, no AVIF/HEIC in most builds.
- Geometry flags (`^`, `!`, `>`, `<`, `%`) work the same.
- `gm mogrify -output-directory dir/` is the equivalent of IM's `mogrify -path dir/` — use it; GM's mogrify also overwrites in place by default.
- No `magick compare` metric parity; `gm compare -metric MSE a.png b.png` exists but supports fewer metrics.

**Rule of thumb:** for plain convert/resize/crop/quality work, GM commands are IM6 commands with `gm ` prefixed. For compositing, text, or modern formats, prefer real ImageMagick and tell the user if only GM is available.
