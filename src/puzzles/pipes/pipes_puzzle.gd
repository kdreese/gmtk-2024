@tool
extends Node2D


const GRID_DIMENSIONS = Vector2i(8, 8)


var sources: Array[Vector2i] = [Vector2i(-1, 3)]
var sinks: Array[Vector2i] = [Vector2i(8, 3)]


func check_water() -> void:
	var tiles_connected: Array[Vector2i] = []

	for source in sources:
		var tile: Vector2i = source

		# Array of arrays. Each element is [tile_to_search, dir_searched_from]
		var tiles_searched: Array = [[tile, Vector2i.ZERO]]
		tiles_connected.append(tile)
		# Array of arrays. Each element is [tile_to_search, dir_from_prev_tile]
		var tiles_to_search: Array = [[tile + Vector2i(1, 0), Vector2i(-1, 0)]]
		while len(tiles_to_search) > 0:
			# Array assignments kiss my ass
			var tile_entry = tiles_to_search.pop_front()
			tiles_searched.append(tile_entry)

			if tile_entry[0] in sinks:
				print("Hooray!")

			var pipe := get_pipe_with_position(tile_entry[0])
			if not pipe:
				continue

			if tile_entry[1] in pipe.get_connected_directions():
				tiles_connected.append(tile_entry[0])
				for direction in pipe.get_connected_directions():
					var new_tile_entry = [tile_entry[0] + direction, -direction]

					if new_tile_entry not in tiles_searched and new_tile_entry not in tiles_to_search:
						tiles_to_search.append(new_tile_entry)

	for pipe in %PipeGrid.get_children() as Array[Pipe]:
		if pipe.grid_position in tiles_connected:
			pipe.set_filled(true)
		else:
			pipe.set_filled(false)


func get_pipe_with_position(pos: Vector2i) -> Pipe:
	for pipe in %PipeGrid.get_children() as Array[Pipe]:
		if pipe.grid_position == pos:
			return pipe

	return null


func generate_grid() -> void:
	for child in %PipeGrid.get_children():
		%PipeGrid.remove_child(child)
		child.queue_free()

	for i in range(GRID_DIMENSIONS.x):
		for j in range(GRID_DIMENSIONS.y):
			var type := [Pipe.X_SHAPE, Pipe.T_SHAPE, Pipe.ELBOW, Pipe.STRAIGHT].pick_random() as int
			var pipe_rotation := [0, 90, 180, 270].pick_random() as int
			var pipe = preload("res://src/puzzles/pipes/pipe.tscn").instantiate()
			pipe.setup(type, pipe_rotation, Vector2i(i, j))
			pipe.rotation_changed.connect(check_water)
			%PipeGrid.add_child(pipe)

	check_water()
