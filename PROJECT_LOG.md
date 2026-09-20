# Project Change Log

Use this file as a concise handoff record when moving development between machines. Add an entry for every project change, including file additions, edits, removals, configuration changes, and important decisions.

## Entry format

```markdown
## YYYY-MM-DD — Short change title

- Changed: `path/to/file`
- Summary: What changed and why.
- Next: Optional follow-up work or verification.
```

---

## 2026-09-19 — Added cross-machine project log

- Changed: `PROJECT_LOG.md`
- Summary: Created the project handoff log. Future changes will be summarized here so the repository itself carries its recent development context between Macs.
- Next: Commit this file once the initial GitHub setup is ready.

## 2026-09-19 — Added the first dungeon level prototype

- Changed: `project.godot`, `scenes/level_01.tscn`, `scripts/dungeon_level.gd`
- Summary: Added an asset-free, Shattered Pixel Dungeon-inspired first floor with hand-authored rooms, stone walls, floor variation, torchlight, a hero marker, stairs, and a compact status bar. Configured the project for a pixel-art 960×540 viewport and the Compatibility renderer for desktop and mobile support.
- Next: Add player movement and wall collision so the prototype can be explored.
