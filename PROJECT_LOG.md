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

## 2026-09-19 — Fixed dungeon-map parser type error

- Changed: `scripts/dungeon_level.gd`, `scripts/dungeon_level.gd.uid`, `project.godot`, `.gitignore`
- Summary: Explicitly convert each dungeon-map character to a `String`, allowing Godot to compile the tile-drawing loop without an ambiguous inferred type. Kept Godot's normalized project settings and source identifier, while excluding its machine-specific editor cache from Git.
- Next: Open the level and run it in Godot to verify the dungeon renders.

## 2026-09-19 — Added grid-based player movement

- Changed: `scripts/dungeon_level.gd`
- Summary: The hero now moves one dungeon tile at a time with either the arrow keys or WASD. Movement is constrained by the hand-authored map, preventing the player from walking through stone walls or outside the level.
- Next: Add mobile touch controls and a camera once the movement feel is confirmed.

## 2026-09-19 — Added persistent field-of-view lighting

- Changed: `scripts/dungeon_level.gd`
- Summary: Replaced static torches and full-map illumination with a five-tile vision radius centered on the hero. Walls block line of sight; cells outside the current view stay concealed until discovered, then remain visible as dimly remembered terrain.
- Next: Tune the vision radius and add mobile touch controls after playtesting the exploration feel.

## 2026-09-19 — Added procedural room-and-corridor generation

- Changed: `scripts/dungeon_level.gd`
- Summary: Replaced the fixed first-floor layout with a generator that creates six to nine non-overlapping rooms and joins them with L-shaped corridors. Each floor has a connected start room and reachable stairs; press `R` during play to generate another layout.
- Next: Add mobile touch controls and populate generated rooms with enemies, loot, and doors.

## 2026-09-19 — Added variable-size dungeon floors and camera

- Changed: `scenes/level_01.tscn`, `scripts/dungeon_level.gd`, `scripts/dungeon_hud.gd`
- Summary: Floors now generate at a random size between 34–42 tiles wide and 21–27 tiles tall, with more rooms to suit the larger space. Added a smooth follow camera constrained to each floor and moved the HUD to a screen layer so it remains fixed during exploration.
- Next: Add mobile touch controls and populate generated rooms with enemies, loot, and doors.

## 2026-09-19 — Added dungeon terrain art references

- Changed: `assets/tiles/terrain/floor_atlas_v1.png`, `assets/tiles/terrain/wall_atlas_v1.png`
- Summary: Added matching dark blue-gray pixel-art floor and wall atlas concepts as the first terrain-art source set. They establish the visual palette and wall depth direction for the eventual import-ready Godot TileSet.
- Next: Normalize the selected art into a strict 32×32 tile grid, then replace the code-drawn terrain with TileMap assets.

## 2026-09-19 — Added import-ready 32×32 terrain tiles

- Changed: `assets/tiles/terrain/floor_tiles_32_v1.png`, `assets/tiles/terrain/wall_tiles_32_v1.png`, `assets/tiles/terrain/dungeon_terrain_tileset.tres`, `assets/tiles/terrain/*.png.import`, `scripts/dungeon_level.gd`
- Summary: Normalized the terrain references into two 128×128 four-by-four atlases with exact 32×32 cells, created a Godot TileSet resource containing both sets, and updated the procedural dungeon renderer to draw the terrain atlas art instead of the original code-drawn stone tiles. Wall variants now respond to neighboring floor cells so caps and corners form coherent dungeon boundaries.
- Next: Refine the atlas variants and use the TileSet directly in a TileMapLayer as terrain rules expand.
