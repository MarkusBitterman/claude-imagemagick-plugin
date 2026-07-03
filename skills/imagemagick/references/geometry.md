# Geometry syntax

Geometry arguments (`-resize`, `-extent`, `-crop`, `-thumbnail`, …) share one grammar:
`WxH{+-}X{+-}Y` with optional flag suffixes. All parts are optional.

## Resize behaviors

| Argument | Meaning |
|---|---|
| `800x600` | Fit within 800×600, preserve aspect ratio (default, never distorts) |
| `800x600!` | Force exactly 800×600, ignoring aspect ratio (distorts) |
| `800x600^` | Fill 800×600 — resize so the *smaller* dimension matches; overflow remains (pair with `-gravity center -extent 800x600` to crop the overflow) |
| `800x600>` | Shrink only if larger than 800×600 (quote in shell!) |
| `800x600<` | Enlarge only if smaller than 800×600 (quote in shell!) |
| `800x` | Width 800, height scaled to preserve aspect |
| `x600` | Height 600, width scaled to preserve aspect |
| `50%` | Scale both dimensions to 50% |
| `50x25%` | Scale width 50%, height 25% |
| `640000@` | Resize to contain at most ~640000 pixels total (area) |

**Shell quoting:** `>`, `<`, `!`, `^`, `%`, `@` are all shell metacharacters in some contexts. Quote every geometry argument: `-resize '800x600>'`.

## Offsets (crop, extent, annotate, composite)

- `-crop 400x300+50+100` — a 400×300 region whose top-left corner is 50 px right, 100 px down.
- Negative offsets (`-50-100`) go left/up from the gravity point.
- Offsets are interpreted relative to the current `-gravity` (default `NorthWest`). With `-gravity center`, `+0+0` means centered.
- After `-crop`, append `+repage` to discard the virtual canvas offset — otherwise later operators (and some formats, notably GIF) remember where the crop came from.

## Common exact-size patterns

```sh
# Cover crop: exactly 800x600, center-cropped, no distortion
magick in.jpg -resize 800x600^ -gravity center -extent 800x600 out.jpg

# Letterbox: exactly 800x600, padded with black bars, no distortion
magick in.jpg -resize 800x600 -background black -gravity center -extent 800x600 out.jpg

# Square thumbnail
magick in.jpg -thumbnail 200x200^ -gravity center -extent 200x200 thumb.jpg
```

## Resize quality

- `-resize` uses a high-quality filter (Lanczos for shrinking) — the right default.
- `-thumbnail` = `-resize` + strips metadata + faster for large shrinks. Use for thumbnails.
- `-scale` uses fast box averaging — blocky, only for pixel-art or speed.
- `-sample` picks nearest pixels — preserves hard pixel edges (pixel art upscale: `-sample 400%`).
- `-liquid-rescale` is content-aware seam carving — a special effect, not a resize.
