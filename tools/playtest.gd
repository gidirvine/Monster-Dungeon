extends SceneTree

# Run with a real renderer for screenshots, or --headless for logic checks only.
var failures: Array[String] = []
var output_dir := "res://playtest-output"
var test_seed := 20260920
var level: Node2D
var captures: Array[String] = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			test_seed = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--output="):
			output_dir = argument.trim_prefix("--output=")
	call_deferred("run_test")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)

func capture(label: String) -> void:
	# Let smoothing settle before capturing the actual rendered game viewport.
	await create_timer(0.7).timeout
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var path := output_dir.path_join(label + ".png")
	check(picture.save_png(path) == OK, "Save screenshot " + label)
	captures.append(path)

func run_test() -> void:
	var absolute_output := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(absolute_output) != OK:
		push_error("Cannot create output directory: " + absolute_output)
		quit(1)
		return
	level = load("res://scenes/level_01.tscn").instantiate()
	root.add_child(level)
	level.set_process_unhandled_input(false)
	level._generate_dungeon(test_seed)
	level._update_visibility()
	level._update_camera()
	level.camera.reset_smoothing()
	level.queue_redraw()
	var start: Vector2i = level.hero_cell
	await capture("01-spawn")

	# Flood fill independently finds a walkable route to the stairs.
	var frontier: Array[Vector2i] = [start]
	var parents: Dictionary = {start: start}
	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor: Vector2i = cell + direction
			if level._is_walkable(neighbor) and not parents.has(neighbor):
				parents[neighbor] = cell
				frontier.append(neighbor)
	check(parents.has(level.stairs_cell), "Stairs must be reachable")
	if not parents.has(level.stairs_cell):
		quit(1)
		return
	var path: Array[Vector2i] = []
	var target: Vector2i = level.stairs_cell
	while target != start:
		path.push_front(target)
		target = parents[target]
	var wall_checks := 0
	for index in path.size():
		var before: Vector2i = level.hero_cell
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not level._is_walkable(before + direction):
				level._try_move(direction)
				check(level.hero_cell == before, "Wall blocks movement")
				wall_checks += 1
		level._try_move(path[index] - before)
		check(level.hero_cell == path[index], "Movement follows route")
		check(level.visible_cells.has(level.hero_cell), "Hero remains visible")
		check(level.explored_cells.has(start), "Spawn remains remembered")
		await process_frame
		if index == path.size() / 2:
			await capture("02-exploration")
	check(level.hero_cell == level.stairs_cell, "Hero reaches stairs")
	await capture("03-stairs")
	# Restarting must clear discoveries from the prior floor.
	level.explored_cells[Vector2i(-99, -99)] = true
	level._generate_dungeon(test_seed + 1)
	check(not level.explored_cells.has(Vector2i(-99, -99)), "Regeneration clears old exploration")
	level._update_visibility()
	level._update_camera()
	level.camera.reset_smoothing()
	level.queue_redraw()
	await capture("04-new-floor")
	var report := {"seed": test_seed, "steps": path.size(), "wall_checks": wall_checks,
		"screenshots": captures, "failures": failures, "passed": failures.is_empty()}
	var file := FileAccess.open(output_dir.path_join("report.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	else:
		check(false, "Cannot save report")
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
