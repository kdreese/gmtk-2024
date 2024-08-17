extends Puzzle

## Possible colors.
enum {
	INVALID = -1,
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

## The tile currently underneath the cursor.
var mouseover_tile: Vector2i = Vector2i(0,0)

var color_to_place: int = INVALID

var unconnected_colors: Array[int]


@onready var background: TileMapLayer = %Background
@onready var wires: TileMapLayer = %Wires


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for color in [RED, GREEN, YELLOW, BLUE]:
		if len(wires.get_used_cells_by_id(0, Vector2i(0, color + 1), 0)) > 0:
			unconnected_colors.append(color)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos := get_local_mouse_position()
		var grid_coords := wires.local_to_map(wires.to_local(mouse_pos))
		if grid_coords != mouseover_tile and LEVEL_BOUNDS.has_point(grid_coords):
			mouse_entered_tile(grid_coords, mouseover_tile)
			mouseover_tile = grid_coords
			if len(unconnected_colors) > 0:
				check_if_connected()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_local_mouse_position()
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
					color_to_place = atlas_coords.y - 1
				else:
					color_to_place = INVALID


func mouse_entered_tile(curr: Vector2i, prev: Vector2i) -> void:
	if color_to_place == -1:
		return

	var direction := curr - prev

	if direction not in [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP]:
		# We didn't go in a cardinal direction.
		color_to_place = INVALID
		return

	var is_impassable := (background.get_cell_atlas_coords(curr) == Vector2i(1,0))
	if is_impassable:
		color_to_place = INVALID
		return

	var connecting_to_tile: bool = false
	var cur_source_id := wires.get_cell_source_id(curr)
	if cur_source_id == 0:
		var atlas_coords := wires.get_cell_atlas_coords(curr)
		if atlas_coords in [Vector2i(0, color_to_place + 1), Vector2i(2, color_to_place + 1)]:
			connecting_to_tile = true
		else:
			color_to_place = INVALID
			return

	var prev_atlas_coords := wires.get_cell_atlas_coords(prev)
	if prev_atlas_coords.x == 0:
		var result := get_vertex_tile_params(direction, true)
		wires.set_cell(prev, 0, Vector2i(result[0], color_to_place + 1), result[1])
	elif prev_atlas_coords.x == 2:
		var alt_tile := wires.get_cell_alternative_tile(prev)
		var direction_2 := get_vertex_direction(alt_tile, false)
		var result := get_edge_tile_params(direction, direction_2)
		wires.set_cell(prev, 0, Vector2i(result[0], color_to_place + 1), result[1])

	# Previous atlas coords were checked when we clicked.
	if connecting_to_tile:
		var cur_atlas_coords := wires.get_cell_atlas_coords(curr)
		if cur_atlas_coords not in [Vector2i(0, color_to_place + 1), Vector2i(2, color_to_place + 1)]:
			color_to_place = INVALID
			return
		if cur_atlas_coords.x == 0:
			var result := get_vertex_tile_params(-direction, true)
			wires.set_cell(curr, 0, Vector2i(result[0], color_to_place + 1), result[1])
			color_to_place = INVALID
		else:
			var alt_tile := wires.get_cell_alternative_tile(curr)
			var direction_2 := get_vertex_direction(alt_tile, false)
			var result := get_edge_tile_params(-direction, direction_2)
			wires.set_cell(curr, 0, Vector2i(result[0], color_to_place + 1), result[1])
	else:
		var result := get_vertex_tile_params(-direction, false)
		wires.set_cell(curr, 0, Vector2i(result[0], color_to_place + 1), result[1])


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
		var starting_nodes := wires.get_used_cells_by_id(0, Vector2i(1, color + 1))
		if len(starting_nodes) == 0:
			continue

		var tile: Vector2i = starting_nodes[0]

		var tiles_searched : Array[Vector2i] = [tile]
		var tiles_to_search : Array[Vector2i] = [tile + get_vertex_direction(wires.get_cell_alternative_tile(tile), true)]
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
			elif atlas_coords.x == 1:
				# We got to the other node.
				color_connected.emit(color)
				colors_to_remove.append(color)

	for color in colors_to_remove:
		unconnected_colors.remove_at(unconnected_colors.find(color))

	if len(unconnected_colors) == 0:
		puzzle_complete.emit()
