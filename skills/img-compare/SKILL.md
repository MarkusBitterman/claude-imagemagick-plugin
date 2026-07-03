---
name: img-compare
description: Visually diff two images — similarity metrics, a difference heatmap, and a labeled side-by-side (e.g. /img-compare before.png after.png)
argument-hint: <two image files, optionally a note about what to look for>
allowed-tools: [Bash, Read, Glob]
---

# /img-compare — visual diff of two images

The user wants two images compared: $ARGUMENTS

## Instructions

1. Consult the `imagemagick` skill in this plugin for syntax and pitfalls. Identify both inputs with `magick identify` first — note dimensions, format, and alpha.
2. **`magick compare` exits 1 when images differ.** That is a result, not an error — append `|| true` or capture the metric from stderr. Only exit code 2 is a real failure.
3. If dimensions differ, say so up front — that alone often answers the question. For pixel comparison, resize a copy of the second image to match the first (`-resize WxH!`) and note that the comparison is post-resize. Never modify the originals.
4. Compute metrics (both write the score to stderr):
   ```sh
   magick compare -metric RMSE a.png b.png null: 2>&1 || true    # 0 = identical
   magick compare -metric SSIM a.png b.png null: 2>&1 || true    # 1 = identical
   ```
5. Build the visual report in one temp/derived location (never overwrite inputs):
   ```sh
   # difference heatmap: red where pixels differ (compare's default rendering)
   magick compare a.png b.png diff.png || true
   # labeled side-by-side including the heatmap
   magick montage -label 'A: %f' a.png -label 'B: %f' b.png -label diff diff.png \
     -tile 3x1 -geometry +8+8 -background '#f4f4f4' compare-report.png
   ```
6. Read the report image to actually look at it, then report: the metric scores with a plain-language read (RMSE near 0 / SSIM near 1 = near-identical), where the differences concentrate, and the path to `compare-report.png`. If the images are identical, say exactly that.
