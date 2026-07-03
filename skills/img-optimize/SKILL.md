---
name: img-optimize
description: Batch web-optimize images into a new directory with a before/after size report (e.g. /img-optimize assets/*.png for the web)
argument-hint: <files, a glob, or a directory — optionally a target format or quality>
allowed-tools: [Bash, Read, Glob]
---

# /img-optimize — batch web optimization with a size report

The user wants images optimized: $ARGUMENTS

## Instructions

1. Consult the `imagemagick` skill — especially `references/formats.md` (encoder choices) and `references/recipes.md` (web-optimization stanzas). Resolve the inputs with Glob; run `magick identify` over them to see formats, dimensions, and alpha before choosing a strategy.
2. **Never optimize in place.** Write to an `optimized/` directory (create it first) or a user-specified destination, preserving filenames.
3. Default strategy, unless the user specified a format:
   - Photographic JPEG/PNG without alpha → WebP: `magick in -quality 80 out.webp`
   - PNG with alpha (UI, logos) → lossless WebP: `-define webp:lossless=true`
   - Keep-format requests → JPEG: `-strip -interlace Plane -sampling-factor 4:2:0 -quality 85`; PNG: `png8:` only when the color count allows it without visible banding
   - Cap oversized dimensions only if the user mentioned a display size: `-resize '1600x1600>'` (quote the `>`)
4. Iterate with a shell loop (not `mogrify`), collecting sizes:
   ```sh
   mkdir -p optimized
   for f in *.jpg; do magick "$f" -strip -quality 85 "optimized/${f%.*}.webp"; done
   ```
5. Verify every output opens (`magick identify optimized/*`) and spot-check the largest one visually with Read if quality was reduced.
6. Report a table: per file, before size → after size and percent saved (`du -b` or `stat -c%s`), plus a totals row. Flag any file that got *bigger* (it happens — already-optimized inputs) and recommend keeping the original for those.
