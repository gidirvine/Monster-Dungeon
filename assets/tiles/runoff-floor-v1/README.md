# Runoff Tunnels floor tiles v1

Four opaque RGBA PNG floor tiles, each exactly 32x32 pixels:
- floor_plain.png
- floor_cracked.png
- floor_mossy.png
- floor_damp.png

floor_atlas_32.png is 64x64 pixels with 32x32 cells, no padding or separation:
top left plain; top right cracked; bottom left mossy; bottom right damp.

Use nearest-neighbor texture filtering. In Godot, set Texture Filter to Nearest
and TileSet tile size and atlas region size to 32x32. These are walkable floor
textures; no collision or gameplay data is included.

All variants share a one-pixel mortar perimeter for interchangeable tiling.
Use plain frequently and the other three as occasional accents.
preview_variants.png and preview_tiled.png are enlarged previews, not atlases.

Artwork generated with built-in image_gen using the accompanying prompt and
the approved sewer concept sheet. Source art was sampled with nearest-neighbor
resizing and its perimeter standardized for exact tile exports. Source and
packaging script are retained in this folder. Existing game assets are unchanged.
