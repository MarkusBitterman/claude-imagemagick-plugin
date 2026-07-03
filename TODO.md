# TODO

## v0.1 — scaffold (done)

- [x] Plugin scaffold from example-plugin framework (`.claude-plugin/plugin.json`, `skills/`)
- [x] `marketplace.json` so the repo is installable directly
- [x] Core model-invoked `imagemagick` skill (command model, quick reference, pitfalls)
- [x] References: geometry, recipes, GM/IM6 compatibility
- [x] User-invoked `/img` command
- [x] CLAUDE.md, TODO.md, README.md, git repo

## v0.2 — verify & harden

- [ ] Test every command in SKILL.md and recipes.md against ImageMagick 7.1.2 locally; fix any that fail
- [ ] Add `test-images/` fixtures (tiny PNG/JPEG/GIF/SVG) + a `scripts/verify-recipes.sh` smoke test
- [ ] Trigger-test the skill description: does "make this image smaller" activate it? Tune phrases
- [ ] Choose a license (example-plugin uses Apache-2.0)
- [ ] Verify `gm-and-im6.md` claims against a real GraphicsMagick install (container or Nix shell: `nix shell nixpkgs#graphicsmagick`)

## v0.3 — more skills

- [ ] `references/formats.md` — format-specific knowledge: PNG bit depths (`png8:`/`png32:`), WebP/AVIF encoder options, HEIC, ICO multi-resolution, TIFF compression
- [ ] `references/color.md` — color management: ICC profiles, sRGB vs linear, `-colorspace` traps, dithering, palette reduction (`-colors`, `-remap`)
- [ ] `references/drawing.md` — `-draw` primitives, gradients, `xc:` canvases, generating placeholder/test images from nothing
- [ ] `references/fx-and-distort.md` — `-fx` expressions, `-distort` (perspective, arc, lens correction), morphology
- [ ] Fred's scripts catalog skill: index the ~380 fmwconcepts scripts by task so Claude can recommend/adapt the right one (respect the non-commercial license — link and describe, don't vendor)
- [ ] `/img-compare` command — visual diff two images (compare + montage side-by-side)
- [ ] `/img-optimize` command — batch web optimization with before/after size report

## v0.4 — polish & publish

- [ ] Screenshot/GIF demo in README
- [ ] Hooks idea: PostToolUse hook that runs `magick identify` on any image file Claude writes, as an automatic sanity check
- [ ] Consider an agent (`agents/`) for long batch jobs over large photo sets
- [ ] Publish to GitHub; test `/plugin marketplace add bittermang/claude-imagemagick-plugin`
- [ ] Maybe: submit to a community marketplace

## Open questions

- GraphicsMagick: first-class support (own skill + tested) or keep as compatibility appendix? Currently appendix, since this machine only has IM7.
- Should `/img` refuse in-place edits entirely, or allow with confirmation? Currently: derive new filename unless user explicitly asks.
- ffmpeg boundary: video→GIF requests currently get "use ffmpeg" — is a companion ffmpeg skill in scope for this plugin or a separate one?
