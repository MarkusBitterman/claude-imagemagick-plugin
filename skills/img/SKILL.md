---
name: img
description: Perform an image operation with ImageMagick — describe the task in plain language (e.g. /img resize photo.jpg to 800px wide as webp)
argument-hint: <task description involving one or more image files>
allowed-tools: [Bash, Read, Glob]
---

# /img — natural-language image operations

The user wants an image operation performed: $ARGUMENTS

## Instructions

1. Consult the `imagemagick` skill in this plugin for command syntax, geometry rules, and pitfalls.
2. Identify the input file(s). If a named file doesn't exist, Glob for likely matches before asking. Run `magick identify` on the inputs first so decisions (quality, alpha handling, color space) are based on the actual image, not assumptions.
3. Build the command per the skill's guidance. **Never overwrite the input file** — derive an output name (`photo.jpg` → `photo-800w.webp`) unless the user explicitly asked for in-place editing.
4. Run it, then verify with `magick identify` on the output (dimensions, format, and file size vs. the original).
5. Report: input → output, final dimensions, and size change. If the request was ambiguous (e.g. "make it smaller" — dimensions or file size?), state the interpretation chosen.
