extends Node2D

const TILE_SIZE := 32
const MAP_OFFSET := Vector2i(0, 0)
const VISION_RADIUS := 5
const MAP_WIDTH := 30
const MAP_HEIGHT := 17
const MIN_ROOM_SIZE := Vector2i(4, 4)
const MAX_ROOM_SIZE := Vector2i(7, 6)
const MIN_ROOMS := 6
const MAX_ROOMS := 9

var dungeon: Array[PackedStringArray] = []
var hero_cell := Vector2i.ZERO
var stairs_cell := Vector2i.ZERO
var visible_cells := {}
var explored_cells := {}

func _ready() -> void:
	_generate_dungeon()
	_update_visibility()
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
		KEY_R:
			_generate_dungeon()
			_update_visibility()
			queue_redraw()


func _generate_dungeon() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	dungeon.clear()
	for y in MAP_HEIGHT:
		var row := PackedStringArray()
		row.resize(MAP_WIDTH)
		for x in MAP_WIDTH:
			row[x] = "#"
		dungeon.append(row)

	var rooms: Array[Rect2i] = []
	var target_room_count := rng.randi_range(MIN_ROOMS, MAX_ROOMS)
	var attempts := 0
	while rooms.size() < target_room_count and attempts < 100:
		attempts += 1
		var room_size := Vector2i(
			rng.randi_range(MIN_ROOM_SIZE.x, MAX_ROOM_SIZE.x),
			rng.randi_range(MIN_ROOM_SIZE.y, MAX_ROOM_SIZE.y)
		)
		var room_position := Vector2i(
			rng.randi_range(1, MAP_WIDTH - room_size.x - 2),
			rng.randi_range(1, MAP_HEIGHT - room_size.y - 2)
		)
		var candidate := Rect2i(room_position, room_size)
		var overlaps_existing_room := false
		for room in rooms:
			if room.grow(1).intersects(candidate):
				overlaps_existing_room = true
				break
		if overlaps_existing_room:
			continue

		_carve_room(candidate)
		if not rooms.is_empty():
			_connect_rooms(_room_center(rooms.back()), _room_center(candidate), rng)
		rooms.append(candidate)

	# The first and last rooms are guaranteed to be connected by the corridors above.
	hero_cell = _room_center(rooms.front())
	stairs_cell = _room_center(rooms.back())
	_set_tile(stairs_cell, ">")


func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			_set_tile(Vector2i(x, y), ".")


func _connect_rooms(from_cell: Vector2i, to_cell: Vector2i, rng: RandomNumberGenerator) -> void:
	# Each L-shaped corridor joins a new room to the prior room, keeping the floor coherent.
	if rng.randi() % 2 == 0:
		_carve_horizontal_tunnel(from_cell.x, to_cell.x, from_cell.y)
		_carve_vertical_tunnel(from_cell.y, to_cell.y, to_cell.x)
	else:
		_carve_vertical_tunnel(from_cell.y, to_cell.y, from_cell.x)
		_carve_horizontal_tunnel(from_cell.x, to_cell.x, to_cell.y)


func _carve_horizontal_tunnel(from_x: int, to_x: int, y: int) -> void:
	for x in range(mini(from_x, to_x), maxi(from_x, to_x) + 1):
		_set_tile(Vector2i(x, y), ".")


func _carve_vertical_tunnel(from_y: int, to_y: int, x: int) -> void:
	for y in range(mini(from_y, to_y), maxi(from_y, to_y) + 1):
		_set_tile(Vector2i(x, y), ".")


func _room_center(room: Rect2i) -> Vector2i:
	return room.position + room.size / 2


func _set_tile(cell: Vector2i, tile: String) -> void:
	var row := dungeon[cell.y]
	row[cell.x] = tile
	dungeon[cell.y] = row


func _get_tile(cell: Vector2i) -> String:
	return dungeon[cell.y][cell.x]


func _try_move(direction: Vector2i) -> void:
	var next_cell := hero_cell + direction
	if next_cell.x < 0 or next_cell.x >= MAP_WIDTH:
		return
	if next_cell.y < 0 or next_cell.y >= MAP_HEIGHT:
		return
	if _get_tile(next_cell) == "#":
		return

	hero_cell = next_cell
	_update_visibility()
	queue_redraw()


func _update_visibility() -> void:
	visible_cells.clear()
	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var cell := Vector2i(x, y)
			if cell.distance_to(hero_cell) <= VISION_RADIUS and _has_line_of_sight(hero_cell, cell):
				visible_cells[cell] = true
				explored_cells[cell] = true


func _has_line_of_sight(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	# Bresenham's line algorithm: a wall can be seen, but blocks cells behind it.
	var current := from_cell
	var delta_x: int = abs(to_cell.x - from_cell.x)
	var delta_y: int = -abs(to_cell.y - from_cell.y)
	var step_x: int = 1 if from_cell.x < to_cell.x else -1
	var step_y: int = 1 if from_cell.y < to_cell.y else -1
	var error: int = delta_x + delta_y

	while current != to_cell:
		var doubled_error: int = 2 * error
		if doubled_error >= delta_y:
			error += delta_y
			current.x += step_x
		if doubled_error <= delta_x:
			error += delta_x
			current.y += step_y
		if current != to_cell and _get_tile(current) == "#":
			return false

	return true


func _draw() -> void:
	# A nearly-black border gives the floor the compact, dungeon-crawler frame.
	draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color("080b12"))

	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var cell := Vector2i(x, y)
			var tile := _get_tile(cell)
			var rect := Rect2(Vector2(MAP_OFFSET + cell * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
			if not explored_cells.has(cell):
				draw_rect(rect, Color("080b12"))
				continue
			if tile == "#":
				_draw_wall(rect, cell)
			else:
				_draw_floor(rect, cell)
				if tile == ">":
					_draw_stairs(rect)
			if not visible_cells.has(cell):
				draw_rect(rect, Color(0.01, 0.02, 0.04, 0.62))

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
	draw_string(font, Vector2(386, 24), "VISION: %s  •  WASD / ARROWS: MOVE  •  R: NEW FLOOR" % VISION_RADIUS, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8fa1a5"))
	draw_string(font, Vector2(838, 24), "HP 20 / 20", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("dc6960"))
