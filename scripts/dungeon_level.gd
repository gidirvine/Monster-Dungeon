extends Node2D

const TILE_SIZE := 32
const MAP_OFFSET := Vector2i(0, 0)

# # is a stone wall, . is walkable floor, > is the stairs to the next floor.
const DUNGEON := [
	"##############################",
	"#............##..............#",
	"#............##..............#",
	"#............................#",
	"#....######..................#",
	"#....#....#....########......#",
	"#....#....#....#......#......#",
	"#....#.........#......#......#",
	"#....######....#......#......#",
	"#..............#..............#",
	"#..............####.#####.....#",
	"#....######.......#.#.........#",
	"#....#....#.......#.#.........#",
	"#....#....#.......#.#.........#",
	"#.........#.......#.#......>..#",
	"#...................#.........#",
	"##############################",
]

const TORCHES := [Vector2i(3, 3), Vector2i(13, 3), Vector2i(21, 5), Vector2i(6, 11), Vector2i(24, 13)]
const HERO_CELL := Vector2i(3, 13)

var hero_cell: Vector2i = HERO_CELL

func _ready() -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_UP, KEY_W:
			_try_move(Vector2i.UP)
		KEY_DOWN, KEY_S:
			_try_move(Vector2i.DOWN)
		KEY_LEFT, KEY_A:
			_try_move(Vector2i.LEFT)
		KEY_RIGHT, KEY_D:
			_try_move(Vector2i.RIGHT)


func _try_move(direction: Vector2i) -> void:
	var next_cell := hero_cell + direction
	if next_cell.x < 0 or next_cell.x >= DUNGEON[0].length():
		return
	if next_cell.y < 0 or next_cell.y >= DUNGEON.size():
		return
	if str(DUNGEON[next_cell.y][next_cell.x]) == "#":
		return

	hero_cell = next_cell
	queue_redraw()


func _draw() -> void:
	# A nearly-black border gives the floor the compact, dungeon-crawler frame.
	draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color("080b12"))

	for y in DUNGEON.size():
		for x in DUNGEON[y].length():
			var cell := Vector2i(x, y)
			var tile: String = str(DUNGEON[y][x])
			var rect := Rect2(Vector2(MAP_OFFSET + cell * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
			if tile == "#":
				_draw_wall(rect, cell)
			else:
				_draw_floor(rect, cell)
				if tile == ">":
					_draw_stairs(rect)

	for torch_cell in TORCHES:
		_draw_torch(torch_cell)

	_draw_hero(hero_cell)
	_draw_hud()


func _draw_floor(rect: Rect2, cell: Vector2i) -> void:
	var alternate := (cell.x + cell.y) % 2 == 0
	draw_rect(rect.grow(-1), Color("202a33") if alternate else Color("1c2630"))
	draw_line(rect.position + Vector2(1, 1), rect.position + Vector2(TILE_SIZE - 2, 1), Color("34414a"), 1.0)
	# Small, deterministic scuffs keep the floor from looking like a flat grid.
	if (cell.x * 11 + cell.y * 7) % 5 == 0:
		var mark := rect.position + Vector2(8 + (cell.y % 3) * 5, 20 - (cell.x % 2) * 4)
		draw_line(mark, mark + Vector2(6, 0), Color("2f3b43"), 1.0)


func _draw_wall(rect: Rect2, cell: Vector2i) -> void:
	draw_rect(rect, Color("111821"))
	draw_rect(rect.grow(-2), Color("38434b"))
	draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(TILE_SIZE - 6, 7)), Color("55606a"))
	draw_rect(Rect2(rect.position + Vector2(3, 10), Vector2(TILE_SIZE - 6, TILE_SIZE - 13)), Color("2d3841"))
	draw_line(rect.position + Vector2(3, 10), rect.position + Vector2(TILE_SIZE - 3, 10), Color("1a222a"), 2.0)
	if (cell.x + cell.y) % 3 == 0:
		draw_line(rect.position + Vector2(9, 14), rect.position + Vector2(9, 27), Color("46525b"), 1.0)


func _draw_torch(cell: Vector2i) -> void:
	var center := Vector2(MAP_OFFSET + cell * TILE_SIZE) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	draw_circle(center, 43.0, Color(0.95, 0.38, 0.08, 0.035))
	draw_circle(center, 28.0, Color(1.0, 0.52, 0.12, 0.08))
	draw_rect(Rect2(center + Vector2(-2, -9), Vector2(4, 12)), Color("6d3b20"))
	draw_circle(center + Vector2(0, -10), 5.0, Color("ffb13b"))
	draw_circle(center + Vector2(0, -11), 2.5, Color("fff1ae"))


func _draw_stairs(rect: Rect2) -> void:
	for step in 4:
		var width := 22 - step * 4
		var position := rect.position + Vector2(16 - width * 0.5, 8 + step * 5)
		draw_rect(Rect2(position, Vector2(width, 4)), Color("9a865c"))


func _draw_hero(cell: Vector2i) -> void:
	var center := Vector2(MAP_OFFSET + cell * TILE_SIZE) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	draw_circle(center + Vector2(1, 3), 10.0, Color("10151b"))
	draw_rect(Rect2(center + Vector2(-7, -2), Vector2(14, 12)), Color("416f92"))
	draw_rect(Rect2(center + Vector2(-5, 1), Vector2(10, 8)), Color("6fa7c9"))
	draw_circle(center + Vector2(0, -6), 7.0, Color("d8b48a"))
	draw_rect(Rect2(center + Vector2(-7, -10), Vector2(14, 4)), Color("d1e5e6"))
	draw_rect(Rect2(center + Vector2(-5, -13), Vector2(10, 4)), Color("86b5ca"))


func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 960, 36), Color("0d1219"))
	draw_line(Vector2(0, 35), Vector2(960, 35), Color("53616a"), 1.0)
	draw_string(font, Vector2(18, 24), "THE FORSAKEN DEPTHS  •  FLOOR 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e2d8b5"))
	draw_string(font, Vector2(420, 24), "WASD / ARROWS: MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8fa1a5"))
	draw_string(font, Vector2(838, 24), "HP 20 / 20", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("dc6960"))
