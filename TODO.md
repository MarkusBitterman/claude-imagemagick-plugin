# TODO

## v0.1 — scaffold (done)

- [x] Plugin scaffold from example-plugin framework (`.claude-plugin/plugin.json`, `skills/`)
- [x] `marketplace.json` so the repo is installable directly
- [x] Core model-invoked `imagemagick` skill (command model, quick reference, pitfalls)
- [x] References: geometry, recipes, GM/IM6 compatibility
- [x] User-invoked `/img` command
- [x] CLAUDE.md, TODO.md, README.md, git repo
- [x] `references/generative.md` — images-from-nothing: canvases, typesetting, effects, distortions
- [x] `scripts/fold-paper.sh` — worked example: .txt → folded-letter photo (verified locally)

## v0.2 — verify & harden (done)

- [x] Test every command in SKILL.md and recipes.md against ImageMagick 7.1.2 locally; fix any that fail
      — also swept geometry.md and generative.md; fixed: missing `mkdir` in batch-loop example,
      bogus `-list pattern` and `-list format-characters`, SVG density math (librsvg scales at
      density/96, not /72), PDF missing-gs vs policy error note, `compare` exit-1 pitfall
- [x] Add `test-images/` fixtures (tiny PNG/JPEG/GIF/SVG) + a `scripts/verify-recipes.sh` smoke test
      — 80 checks; PDF/PS cases skip without Ghostscript (run via `nix shell nixpkgs#ghostscript`)
- [x] Trigger-test the skill description: does "make this image smaller" activate it? Tune phrases
      — headless `claude --plugin-dir … -p` runs: all 3 phrasings (webp convert, "make smaller",
      watermark) invoked `imagemagick:imagemagick`; no tuning needed
- [x] Choose a license (example-plugin uses Apache-2.0) — Apache-2.0; LICENSE + plugin.json field
- [x] Verify `gm-and-im6.md` claims against a real GraphicsMagick install (container or Nix shell: `nix shell nixpkgs#graphicsmagick`)
      — GM 1.3.47: fixed `-annotate` (doesn't exist at all), `label:`/`caption:` (do auto-size),
      exact compare metric list, `caption:@file` hangs GM

## v0.3 — more skills (done)

- [x] `references/formats.md` — format-specific knowledge: PNG bit depths (`png8:`/`png32:`), WebP/AVIF encoder options, HEIC, ICO multi-resolution, TIFF compression
      — also covers JPEG XL (libjxl present in modern builds); found `heic:speed` is AVIF-only here
- [x] `references/color.md` — color management: ICC profiles, sRGB vs linear, `-colorspace` traps, dithering, palette reduction (`-colors`, `-remap`)
      — ICC assign-vs-convert verified with real profiles (colord); Gray keeps sRGB gamma, RGB/LinearGray linearize (measured)
- [x] `references/drawing.md` — `-draw` primitives, gradients, `xc:` canvases, generating placeholder/test images from nothing
      — canvases stayed in generative.md (cross-linked) to avoid duplication; includes placehold.co-style recipe
- [x] `references/fx-and-distort.md` — `-fx` expressions, deeper `-distort` coverage (SRT, arc, lens correction, displacement maps), morphology
      — displacement is `-compose displace`, not a distort; `-fx` has no string literals; fx-vs-evaluate perf gap measured small for simple exprs
- [x] More worked scripts alongside fold-paper.sh: page curl, coffee-stain/aged paper, screenshot-to-browser-mockup, sprite-sheet slicer
      — shipped as page-turn.sh (renamed: no curl confusion), age-paper.sh, browser-mockup.sh,
      sprite-slice.sh, plus paper-stack.sh (README-as-paper flagship demo) and social-card.sh;
      found+documented: -compose is sticky across -layers merge; softlight blows midtone
      overlays to white on Q16-HDRI (use overlay)
- [x] ~~Fred's scripts catalog~~ → dropped by design: no third-party references in plugin content.
      Instead: an original effects library ("spiritual successor"), three lanes — fresh takes on
      the classic effects, modern gaps the old collections never covered (web/social/dev
      workflows), repeatable tools over one-off filters. First six scripts shipped above.
- [x] `/img-compare` command — visual diff two images (compare + montage side-by-side)
      — metrics (RMSE/SSIM) + diff heatmap + labeled montage; documents the exit-1 gotcha
- [x] `/img-optimize` command — batch web optimization with before/after size report
      — per-format strategy from formats.md, never in-place, flags files that got bigger

Versioning: one milestone chunk per minor version, rolling 0.4 → 0.5 → … → 0.9 → 1.0 and onward.

## v0.4 — agents, chunk one (done)

- [x] Consider an agent (`agents/`) for long batch jobs over large photo sets
      — chunk one shipped: photo-batch (sample-first, chunked, verified, compact report) and
      image-auditor (read-only; privacy/EXIF-GPS leaks first-class; fix command per finding);
      both preload the imagemagick skill via `skills:` frontmatter; headless-verified routing
- [x] Fix + verify the marketplace install flow — the reported failure was two commands pasted
      as one line (URL became malformed); README now says to run them one at a time; flow
      validated locally with the `claude plugin` CLI

## v0.5 — agents, chunk two (done)

- [x] effect-artist (generate → look → self-critique → iterate loop) and
      design-critic — a collaborative second set of eyes on UI/design screenshots: themes,
      structure, areas for improvement; accessibility and UX checks; "bad but close" calls
      where a color/alignment tweak rescues the design; direction-shaping guidance when the
      user's intent is still ambiguous. Ground critique in measurements (palette extraction,
      WCAG-ish contrast sampling, whitespace/alignment metrics); annotated-screenshot callouts
      best-effort, not the contract. Complements the official frontend-design plugin (it
      generates, we critique) — no hard dependency.
      — measurement recipes verified vs known answers: `-colorspace LinearGray` +
      `%[fx:(maxima+0.05)/(minima+0.05)]` reproduces WCAG 4.54:1 for #767676-on-white
      (LinearGray = Rec.709 linear, same model WCAG uses); `%@` trims against the *corner*
      color (full-bleed headers skew margins — crop to panel first); pixel-sample flat fills,
      never glyph edges. effect-artist: criteria fixed *before* generating; iterate at final
      resolution (blur/pointsize/shadow params are absolute px); ~5-iteration cap.
      Routing: design-critic activates on natural phrasing ("second set of eyes",
      accessibility check); effect-artist verified via explicit invocation — one-shot
      "generate X" phrasings stay inline with the skill, which is the right split (agent =
      iteration offload). Headless routing tests MUST pass `--permission-mode acceptEdits`:
      this machine defaults to plan mode, and `-p` runs stall at ExitPlanMode with no user
      to approve (burned several runs learning this).

## Rolling backlog (each future chunk takes the next version number)

## v0.6 — effects library, chunk one (done)

- [x] Effects library backlog (originals, verify-first): tiny-planet (DePolar), tilt-shift,
      vignette presets, LQIP/blurred-placeholder generator, favicon-pack.sh (logo → ICO+PNG set),
      watermark-batch.sh, qr-brand.sh (style a QR from `qrencode` — IM can't do Reed-Solomon
      itself; needs the qrencode dependency)
      — all seven shipped, each prototyped on synthesized fixtures and eyeballed before
      scripting. Found: tiny planet is `-distort Polar 0` (DePolar *unwraps* — the backlog
      entry had it backwards), with `-rotate 180` first (ground→center) and
      `-virtual-pixel edge` to fill the square's corners with sky; tilt-shift masks built
      via `-fx` on a 1px column then `-scale`d wide (fast) — flat/gradient test images hide
      blur, verify on detail; radial-gradient vignettes need
      `-define gradient:extent=DiagonalDistance` + `-level` white-holds or multiply dims the
      whole frame; a 140-byte 24px WebP makes a usable LQIP but `-strip` is load-bearing
      (ICC alone can outweigh the pixels); iOS apple-touch icons get flattened (transparent
      renders on black), and detailed logos mush out at 16px; branded QR verified
      end-to-end with zbarimg scan-back (qrencode -l H survives recolor + 20%-width logo).
      Smoke test now covers all scripts; full run:
      `nix shell nixpkgs#ghostscript nixpkgs#qrencode nixpkgs#zbar --command scripts/verify-recipes.sh`
- [ ] Hooks idea: PostToolUse hook that runs `magick identify` on any image file Claude writes, as an automatic sanity check
- [ ] Confirm install + usage from a completely fresh conversation (user test drive)
- [ ] Submit to the official directory: https://clau.de/plugin-directory-submission (needs license ✓, category, tagged release — `claude plugin tag` can cut the tag)
- [x] Screenshot/GIF demo in README — `demo/` images generated by ImageMagick itself via `scripts/make-demo.sh`
- [x] Publish to GitHub: https://github.com/MarkusBitterman/claude-imagemagick-plugin

## Open questions

- GraphicsMagick: first-class support (own skill + tested) or keep as compatibility appendix? Currently appendix, since this machine only has IM7.
- Should `/img` refuse in-place edits entirely, or allow with confirmation? Currently: derive new filename unless user explicitly asks.
- ffmpeg boundary: video→GIF requests currently get "use ffmpeg" — is a companion ffmpeg skill in scope for this plugin or a separate one?
