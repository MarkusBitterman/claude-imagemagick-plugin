# claude-imagemagick-plugin

ImageMagick/GraphicsMagick expertise for [Claude Code](https://claude.com/claude-code) — teaches Claude the IM7 command model, geometry grammar, batch-processing safety, and recipes for common image tasks.

## What you get

- **`imagemagick` skill** (model-invoked) — activates automatically when you ask Claude to resize, convert, crop, compress, composite, watermark, annotate, or batch-process images. Includes on-demand references for geometry syntax, multi-step recipes, and GraphicsMagick/IM6 compatibility.
- **`/img` command** (user-invoked) — `/img resize photo.jpg to 800px wide as webp`. Inspects inputs first, never overwrites originals, verifies outputs.

## Install

```
/plugin marketplace add MarkusBitterman/claude-imagemagick-plugin
/plugin install imagemagick
```

Or for local development:

```sh
claude --plugin-dir /path/to/claude-imagemagick-plugin
```

Requires ImageMagick (v7 preferred; v6 and GraphicsMagick are handled with reduced coverage).

## Structure

Modeled on the official [example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin):

```
.claude-plugin/plugin.json      plugin metadata
.claude-plugin/marketplace.json direct-install support
skills/imagemagick/             model-invoked skill + references/
skills/img/                     /img slash command
CLAUDE.md                       contributor guidance
TODO.md                         roadmap
```

## Status

v0.2 — all documented commands verified against ImageMagick 7.1.2 (and GraphicsMagick 1.3.x for the compatibility reference); smoke test in `scripts/verify-recipes.sh`. See [TODO.md](TODO.md) for the roadmap.

## License

[Apache-2.0](LICENSE)
