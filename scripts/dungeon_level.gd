extends Node2D

const TILE_SIZE := 32
const MAP_OFFSET := Vector2i(0, 0)
const VISION_RADIUS := 5
const MIN_MAP_WIDTH := 34
const MAX_MAP_WIDTH := 42
const MIN_MAP_HEIGHT := 21
const MAX_MAP_HEIGHT := 27
const MIN_ROOM_SIZE := Vector2i(4, 4)
const MAX_ROOM_SIZE := Vector2i(8, 7)
const MIN_ROOMS := 9
const MAX_ROOMS := 14
const FLOOR_ATLAS: Texture2D = preload("res://assets/tiles/terrain/floor_tiles_32_v1.png")
const WALL_ATLAS: Texture2D = preload("res://assets/tiles/terrain/wall_tiles_32_v2.png")

var dungeon: Array[PackedStringArray] = []
var hero_cell := Vector2i.ZERO
var stairs_cell := Vector2i.ZERO
var visible_cells := {}
var explored_cells := {}
var map_width := MIN_MAP_WIDTH
var map_height := MIN_MAP_HEIGHT

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	_generate_dungeon()
	_update_visibility()
	_update_camera()
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
			_update_camera()
			queue_redraw()


func _generate_dungeon() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	map_width = rng.randi_range(MIN_MAP_WIDTH, MAX_MAP_WIDTH)
	map_height = rng.randi_range(MIN_MAP_HEIGHT, MAX_MAP_HEIGHT)
	dungeon.clear()
	for y in map_height:
		var row := PackedStringArray()
		row.resize(map_width)
		for x in map_width:
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
			rng.randi_range(1, map_width - room_size.x - 2),
			rng.randi_range(1, map_height - room_size.y - 2)
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


func _update_camera() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_width * TILE_SIZE
	camera.limit_bottom = map_height * TILE_SIZE
	camera.position = _cell_center(hero_cell)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(MAP_OFFSET + cell * TILE_SIZE) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


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
	if next_cell.x < 0 or next_cell.x >= map_width:
		return
	if next_cell.y < 0 or next_cell.y >= map_height:
		return
	if _get_tile(next_cell) == "#":
		return

	hero_cell = next_cell
	_update_visibility()
	_update_camera()
	queue_redraw()


func _update_visibility() -> void:
	visible_cells.clear()
	for y in map_height:
		for x in map_width:
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
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_width * TILE_SIZE, map_height * TILE_SIZE)), Color("080b12"))

	for y in map_height:
		for x in map_width:
			var cell := Vector2i(x, y)
			var tile := _get_tile(cell)
			var rect := Rect2(Vector2(MAP_OFFSET + cell * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
			if not explored_cells.has(cell):
				draw_rect(rect, Color("080b12"))
				continue
			if tile == "#":
				if _is_boundary_wall(cell):
					_draw_wall(rect, cell)
				else:
					draw_rect(rect, Color("080b12"))
			else:
				_draw_floor(rect, cell)
				if tile == ">":
					_draw_stairs(rect)
			if not visible_cells.has(cell):
				draw_rect(rect, Color(0.01, 0.02, 0.04, 0.62))

	_draw_hero(hero_cell)


func _draw_floor(rect: Rect2, cell: Vector2i) -> void:
	_draw_atlas_tile(FLOOR_ATLAS, rect, (cell.x * 7 + cell.y * 11) % 16)


func _draw_wall(rect: Rect2, cell: Vector2i) -> void:
	# Wall texture exists only on the boundary of explored space; deeper rock stays black.
	_draw_atlas_tile(WALL_ATLAS, rect, (cell.x * 5 + cell.y * 3) % 16)
	var cap_color := Color("9aacad")
	var shadow_color := Color("35474f")
	if _is_walkable(cell + Vector2i.UP):
		draw_rect(Rect2(rect.position, Vector2(TILE_SIZE, 3)), cap_color)
		draw_line(rect.position + Vector2(0, 3), rect.position + Vector2(TILE_SIZE, 3), shadow_color, 1.0)
	if _is_walkable(cell + Vector2i.DOWN):
		var bottom := rect.position + Vector2(0, TILE_SIZE - 3)
		draw_rect(Rect2(bottom, Vector2(TILE_SIZE, 3)), cap_color)
		draw_line(bottom - Vector2(0, 1), bottom + Vector2(TILE_SIZE, -1), shadow_color, 1.0)
	if _is_walkable(cell + Vector2i.LEFT):
		draw_rect(Rect2(rect.position, Vector2(3, TILE_SIZE)), cap_color)
		draw_line(rect.position + Vector2(3, 0), rect.position + Vector2(3, TILE_SIZE), shadow_color, 1.0)
	if _is_walkable(cell + Vector2i.RIGHT):
		var right := rect.position + Vector2(TILE_SIZE - 3, 0)
		draw_rect(Rect2(right, Vector2(3, TILE_SIZE)), cap_color)
		draw_line(right - Vector2(1, 0), right + Vector2(-1, TILE_SIZE), shadow_color, 1.0)


func _is_boundary_wall(cell: Vector2i) -> bool:
	return _is_walkable(cell + Vector2i.UP) or _is_walkable(cell + Vector2i.DOWN) or _is_walkable(cell + Vector2i.LEFT) or _is_walkable(cell + Vector2i.RIGHT)


func _is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= map_width or cell.y < 0 or cell.y >= map_height:
		return false
	return _get_tile(cell) != "#"


func _draw_atlas_tile(atlas: Texture2D, destination: Rect2, tile_index: int) -> void:
	var atlas_cell := Vector2i(tile_index % 4, tile_index / 4)
	var source := Rect2(Vector2(atlas_cell * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
	draw_texture_rect_region(atlas, destination, source)


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
