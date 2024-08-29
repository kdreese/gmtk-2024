extends Puzzle

## Possible colors.
enum {
	INVALID = -1,
	PURPLE,
	RED,
	GREEN,
	BLUE,
	YELLOW,
}

## The size of the level.
const LEVEL_BOUNDS := Rect2i(0, 0, 8, 8)

## Alternative tile flags for 0, 90, 180, and 270 degree clockwise rotations.
const ROTATION_FLAGS = [
	0,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
]

## Emitted when a color is connected to its node.
signal color_connected(color: int)

@export var puzzle_to_load: PackedScene

var puzzle: Node2D

## The tile currently underneath the cursor.
var mouseover_tile: Vector2i = Vector2i(0,0)

var last_valid_tile: Vector2i = Vector2i(0,0)

var color_to_place: int = INVALID

var unconnected_colors: Array[int]

## The state of the wire tilemap upon reset.
var reset_state: PackedByteArray

var background: TileMapLayer
var wires: TileMapLayer

var disabled_stylebox: StyleBoxFlat
var active_stylebox: StyleBoxFlat


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_stylebox = $Highlight.get_theme_stylebox("panel")
	disabled_stylebox = active_stylebox.duplicate()
	disabled_stylebox.border_color = Color(0.3, 0.3, 0.3, 1.0)
	load_puzzle(puzzle_to_load)
	reset()


func load_puzzle(new_puzzle: PackedScene) -> void:
	if puzzle != null:
		remove_child(puzzle)
		puzzle.queue_free()
	puzzle = new_puzzle.instantiate() as Node2D
	background = puzzle.get_node("Background")
	wires = puzzle.get_node("Wires")
	reset_state = wires.tile_map_data
	add_child(puzzle)
	reset()


func reset() -> void:
	unconnected_colors = []
	wires.tile_map_data = reset_state
	for color in [PURPLE, RED, GREEN, YELLOW, BLUE]:
		if len(wires.get_used_cells_by_id(0, Vector2i(0, color), 0)) > 0:
			unconnected_colors.append(color)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		show_highlight()
		var mouse_pos := get_global_mouse_position()
		var grid_coords := wires.local_to_map(wires.to_local(mouse_pos))
		if grid_coords != mouseover_tile and LEVEL_BOUNDS.has_point(grid_coords):
			mouse_entered_tile(grid_coords)
			mouseover_tile = grid_coords
			if len(unconnected_colors) > 0:
				check_if_connected()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_global_mouse_position()
			var grid_coords := wires.local_to_map(wires.to_local(mouse_pos))
			if not LEVEL_BOUNDS.has_point(grid_coords):
				# We're outside the level boundary
				return
			if not event.pressed:
				color_to_place = INVALID
			elif wires.get_cell_source_id(grid_coords) != 0:
				# We clicked on nothing.
				color_to_place = INVALID
			else:
				var atlas_coords := wires.get_cell_atlas_coords(grid_coords)
				if atlas_coords.x in [0, 2]:
					color_to_place = atlas_coords.y
					last_valid_tile = grid_coords
				elif atlas_coords.x == 1:
					clear_path(follow_path(grid_coords))
					color_to_place = atlas_coords.y
					if color_to_place not in unconnected_colors:
						unconnected_colors.append(color_to_place)
					last_valid_tile = grid_coords
				else:
					color_to_place = INVALID


func show_highlight() -> void:
	var mouse_pos := get_global_mouse_position()
	var mouse_grid_pos := wires.local_to_map(wires.to_local(mouse_pos))
	var atlas_coords := wires.get_cell_atlas_coords(mouse_grid_pos)
	if atlas_coords.x in [0, 1, 2]:
		$Highlight.add_theme_stylebox_override("panel", active_stylebox)
	else:
		$Highlight.add_theme_stylebox_override("panel", disabled_stylebox)
	if LEVEL_BOUNDS.has_point(mouse_grid_pos):
		$Highlight.show()
		$Highlight.position = 64.0 * mouse_grid_pos
	else:
		$Highlight.hide()


func mouse_entered_tile(new: Vector2i) -> void:
	if color_to_place == INVALID:
		return

	var full_direction := new - last_valid_tile

	if full_direction.sign().length_squared() != 1:
		# We didn't go in a cardinal direction (any number of steps).
		return

	var direction := full_direction.sign()
	var steps := int(full_direction.length())

	var curr := last_valid_tile
	for i in range(steps):
		curr += direction
		var is_impassable := (background.get_cell_atlas_coords(curr) == Vector2i(1,0))
		if is_impassable:
			if curr == new:
				$WrongSound.play()
			return

		var connecting_to_tile: bool = false
		var cur_source_id := wires.get_cell_source_id(curr)
		if cur_source_id == 0:
			var atlas_coords := wires.get_cell_atlas_coords(curr)
			if atlas_coords in [Vector2i(0, color_to_place), Vector2i(2, color_to_place)]:
				connecting_to_tile = true
			else:
				if curr == new:
					$WrongSound.play()
				return

		var prev_atlas_coords := wires.get_cell_atlas_coords(last_valid_tile)
		if prev_atlas_coords.x == 0:
			var result := get_vertex_tile_params(direction, true)
			wires.set_cell(last_valid_tile, 0, Vector2i(result[0], color_to_place), result[1])
		elif prev_atlas_coords.x == 2:
			var alt_tile := wires.get_cell_alternative_tile(last_valid_tile)
			var direction_2 := get_vertex_direction(alt_tile, false)
			var result := get_edge_tile_params(direction, direction_2)
			wires.set_cell(last_valid_tile, 0, Vector2i(result[0], color_to_place), result[1])

		# Previous atlas coords were checked when we clicked.
		if connecting_to_tile:
			var cur_atlas_coords := wires.get_cell_atlas_coords(curr)
			if cur_atlas_coords not in [Vector2i(0, color_to_place), Vector2i(2, color_to_place)]:
				if curr == new:
					$WrongSound.play()
				return
			if cur_atlas_coords.x == 0:
				var result := get_vertex_tile_params(-direction, true)
				wires.set_cell(curr, 0, Vector2i(result[0], color_to_place), result[1])
				color_to_place = INVALID
			else:
				var alt_tile := wires.get_cell_alternative_tile(curr)
				var direction_2 := get_vertex_direction(alt_tile, false)
				var result := get_edge_tile_params(-direction, direction_2)
				wires.set_cell(curr, 0, Vector2i(result[0], color_to_place), result[1])
				color_to_place = INVALID
		else:
			var result := get_vertex_tile_params(-direction, false)
			wires.set_cell(curr, 0, Vector2i(result[0], color_to_place), result[1])

		if not connecting_to_tile:
			$PlaceSound.play()

		last_valid_tile = curr


func get_edge_directions(atlas_coords: Vector2i, alternative_tile: int) -> Array[Vector2i]:
	if atlas_coords.x == 3:
		if alternative_tile == 0:
			return [Vector2i.DOWN, Vector2i.LEFT]
		elif alternative_tile == ROTATION_FLAGS[1]:
			return [Vector2i.UP, Vector2i.LEFT]
		elif alternative_tile == ROTATION_FLAGS[2]:
			return [Vector2i.UP, Vector2i.RIGHT]
		elif alternative_tile == ROTATION_FLAGS[3]:
			return [Vector2i.RIGHT, Vector2i.DOWN]
		else:
			push_error("Invalid alternative tile")
			return []
	elif atlas_coords.x == 4:
		if alternative_tile == 0 or alternative_tile == ROTATION_FLAGS[2]:
			return [Vector2i.RIGHT, Vector2i.LEFT]
		elif alternative_tile == ROTATION_FLAGS[1] or alternative_tile == ROTATION_FLAGS[3]:
			return [Vector2i.UP, Vector2i.DOWN]
		else:
			push_error("Invalid alternative tile")
			return []
	else:
		push_error("Not an edge tile.")
		return []


func get_edge_tile_params(dir_1: Vector2i, dir_2: Vector2i) -> Array[int]:
	if dir_1 not in [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP]:
		push_error("Invalid direction")
		return []

	if dir_2 not in [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP]:
		push_error("Invalid direction")
		return []

	if dir_1 == dir_2:
		push_error("Directions match")
		return []

	match [dir_1, dir_2]:
		[Vector2i.UP, Vector2i.RIGHT],[Vector2i.RIGHT, Vector2i.UP]:
			return [3, ROTATION_FLAGS[2]]
		[Vector2i.UP, Vector2i.DOWN],[Vector2i.DOWN, Vector2i.UP]:
			return [4, ROTATION_FLAGS[1]]
		[Vector2i.UP, Vector2i.LEFT],[Vector2i.LEFT, Vector2i.UP]:
			return [3, ROTATION_FLAGS[1]]
		[Vector2i.RIGHT, Vector2i.DOWN],[Vector2i.DOWN, Vector2i.RIGHT]:
			return [3, ROTATION_FLAGS[3]]
		[Vector2i.RIGHT, Vector2i.LEFT],[Vector2i.LEFT, Vector2i.RIGHT]:
			return [4, 0]
		[Vector2i.DOWN, Vector2i.LEFT],[Vector2i.LEFT, Vector2i.DOWN]:
			return [3, 0]
		_:
			push_error("Fell out of match statement")
			return []


func get_vertex_direction(alt_tile: int, is_node: bool = false) -> Vector2i:
	if is_node:
		if alt_tile == 0:
			return Vector2i.RIGHT
		elif alt_tile == ROTATION_FLAGS[1]:
			return Vector2i.DOWN
		elif alt_tile == ROTATION_FLAGS[2]:
			return Vector2i.LEFT
		elif alt_tile == ROTATION_FLAGS[3]:
			return Vector2i.UP
		else:
			push_error("Invalid alt tile")
			return Vector2i.ZERO
	else:
		if alt_tile == 0:
			return Vector2i.LEFT
		elif alt_tile == ROTATION_FLAGS[1]:
			return Vector2i.UP
		elif alt_tile == ROTATION_FLAGS[2]:
			return Vector2i.RIGHT
		elif alt_tile == ROTATION_FLAGS[3]:
			return Vector2i.DOWN
		else:
			push_error("Invalid alt tile")
			return Vector2i.ZERO


# Returns [atlas_coords.x, alt_tile_flags]
func get_vertex_tile_params(dir: Vector2i, is_node: bool = false) -> Array[int]:
	if dir not in [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP]:
		push_error("Invalid direction")
		return []

	if is_node:
		if dir == Vector2i.RIGHT:
			return [1, 0]
		elif dir == Vector2i.DOWN:
			return [1, ROTATION_FLAGS[1]]
		elif dir == Vector2i.LEFT:
			return [1, ROTATION_FLAGS[2]]
		else:
			return [1, ROTATION_FLAGS[3]]
	else:
		if dir == Vector2i.LEFT:
			return [2, 0]
		elif dir == Vector2i.UP:
			return [2, ROTATION_FLAGS[1]]
		elif dir == Vector2i.RIGHT:
			return [2, ROTATION_FLAGS[2]]
		else:
			return [2, ROTATION_FLAGS[3]]


func check_if_connected() -> void:
	var colors_to_remove = []
	for color in unconnected_colors:
		# Only check connected nodes.
		var starting_nodes := wires.get_used_cells_by_id(0, Vector2i(1, color))
		if len(starting_nodes) == 0:
			continue

		for tile in follow_path(starting_nodes[0]):
			if tile == starting_nodes[0]:
				# Ignore the start tile.
				continue
			if wires.get_cell_atlas_coords(tile) == Vector2i(1, color):
				# We got to the other node.
				$CompleteSound.play()
				color_connected.emit(color)
				colors_to_remove.append(color)

	for color in colors_to_remove:
		unconnected_colors.remove_at(unconnected_colors.find(color))

	if len(unconnected_colors) == 0:
		puzzle_complete.emit()


## Follow of path of wires. Returns a list of cells containing wire tiles.
func follow_path(starting_tile: Vector2i) -> Array[Vector2i]:
	var tile := starting_tile
	var tiles_searched: Array[Vector2i] = [tile]
	var tiles_to_search: Array[Vector2i] = [tile + get_vertex_direction(wires.get_cell_alternative_tile(tile), true)]
	while len(tiles_to_search) > 0:
		tile = tiles_to_search.pop_front()
		tiles_searched.append(tile)
		if wires.get_cell_source_id(tile) != 0:
			continue
		var atlas_coords := wires.get_cell_atlas_coords(tile)
		var alt_tile := wires.get_cell_alternative_tile(tile)
		if atlas_coords.x in [3, 4]:
			for direction in get_edge_directions(atlas_coords, alt_tile):
				var new_tile = tile + direction
				if (new_tile not in tiles_searched) and (new_tile not in tiles_to_search):
					tiles_to_search.append(new_tile)

	return tiles_searched


## Clear a path of wires. Keeps the contacts in place, but disconnects them.
func clear_path(tiles: Array[Vector2i]) -> void:
	for tile in tiles:
		var atlas_coords := wires.get_cell_atlas_coords(tile)
		if atlas_coords.x == 1:
			wires.set_cell(tile, 0, Vector2i(0, atlas_coords.y), ROTATION_FLAGS[0])
		elif atlas_coords.x in [2, 3, 4]:
			wires.set_cell(tile, -1)
