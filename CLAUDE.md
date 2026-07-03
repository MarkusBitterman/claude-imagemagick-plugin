# claude-imagemagick-plugin

A Claude Code plugin providing ImageMagick/GraphicsMagick expertise. Modeled on
[`plugins/example-plugin`](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin)
from the official plugins repo.

## Structure

```
.claude-plugin/
  plugin.json           # plugin metadata (name: "imagemagick")
  marketplace.json      # makes this repo installable via /plugin marketplace add
skills/
  imagemagick/          # model-invoked: auto-activates on image-manipulation requests
    SKILL.md            # command model, quick reference, pitfalls — keep SMALL
    references/         # loaded on demand, not on activation — put depth here
      geometry.md       # resize/crop geometry grammar
      recipes.md        # multi-step patterns (watermark, GIF, PDF, web-optimize)
      gm-and-im6.md     # GraphicsMagick + ImageMagick 6 compatibility
  img/                  # user-invoked: /img <natural-language task>
    SKILL.md
TODO.md                 # roadmap — check here before adding features
```

## Conventions

- **Skill format:** `skills/<name>/SKILL.md` only. Do not add a `commands/` directory — that layout is legacy per the example-plugin.
- **Model-invoked skills** need `description` frontmatter written as trigger conditions: quoted phrases a user would actually say ("resize an image", "convert PNG to WebP"). This field is the entire activation mechanism — be generous with trigger phrases.
- **SKILL.md stays small; `references/` holds depth.** SKILL.md is injected into context whenever the skill activates; reference files are read only when needed. New deep-dive content goes in `references/`, with a one-line pointer from SKILL.md.
- **IM7 syntax first.** All examples use `magick` (never bare `convert`). GM/IM6 differences live only in `gm-and-im6.md`.
- **Safety is a content requirement:** any documented command that can destroy user files (`mogrify`, in-place edits, JPEG alpha-drop) must carry its warning inline, next to the command.
- Quote shell-metacharacter geometry flags in every example: `-resize '800x600>'`.

## Testing changes

- Smoke test: `scripts/verify-recipes.sh` runs every documented command against the
  `test-images/` fixtures. The command list is hand-maintained — when you add or edit a
  command in SKILL.md or `references/*.md`, add/update the matching line there. Run PDF/PS
  cases with `nix shell nixpkgs#ghostscript --command scripts/verify-recipes.sh`.
- Validate JSON: `python3 -m json.tool .claude-plugin/plugin.json`
- Load locally: `claude --plugin-dir /home/bittermang/Developments/claude-imagemagick-plugin`, then check the skills appear in `/help` and that `/img` works.
- Trigger-test the model-invoked skill with a natural request ("convert test.png to webp") and confirm it activates.
- Verify documented commands against the real binary before committing — this machine has ImageMagick 7.1.2 Q16-HDRI (Nix). GraphicsMagick is not installed, but `gm-and-im6.md` claims can be (and were, v0.2: GM 1.3.47 Q8) verified via `nix shell nixpkgs#graphicsmagick`.

## Upstream references

- Command-line options: https://imagemagick.org/command-line-options/
- Usage examples: https://imagemagick.org/examples/
- GraphicsMagick: http://www.graphicsmagick.org/utilities.html

Note: third-party script collections (e.g. fmwconcepts) carry restrictive licenses —
do not reference, vendor, or port them in plugin content. Effects ship as original
IM7 implementations in `skills/imagemagick/scripts/`, verified locally.
