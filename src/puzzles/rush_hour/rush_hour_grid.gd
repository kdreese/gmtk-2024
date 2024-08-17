class_name RushHourGrid
extends Control

const GRID_SIZE := 80
const TWEEN_DURATION := 0.1

## The boundary tiles, as a list of grid coords.
const BOUNDARY_TILES: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(-1, 2),
	Vector2i(-1, 3),
	Vector2i(-1, 4),
	Vector2i(-1, 5),
	Vector2i(0, 6),
	Vector2i(1, 6),
	Vector2i(2, 6),
	Vector2i(3, 6),
	Vector2i(4, 6),
	Vector2i(5, 6),
	Vector2i(6, 5),
	Vector2i(6, 4),
	Vector2i(6, 3),
	# Vector2i(6, 2), EXIT (temp)
	Vector2i(6, 1),
	Vector2i(6, 0),
	Vector2i(5, -1),
	Vector2i(4, -1),
	Vector2i(3, -1),
	Vector2i(2, -1),
	Vector2i(1, -1),
	Vector2i(0, -1),
]

# Parameters for the selected block.
var selected_block: RushHourBlock = null
var block_initial_position := Vector2.ZERO
var mouse_initial_position := Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for block in %Blocks.get_children() as Array[RushHourBlock]:
		block.selected.connect(block_selected)
		block.released.connect(block_released)


## The user clicked on a block.
func block_selected(block: RushHourBlock) -> void:
	if selected_block == null:
		selected_block = block
		block_initial_position = block.position
		mouse_initial_position = get_global_mouse_position()


## The user let go of the left mouse button.
func block_released(block: RushHourBlock) -> void:
	if selected_block != block:
		push_error("Unexpected release.")

	# Collision is handled in _input, this should be a good position value.
	var final_position := block.position.snappedf(GRID_SIZE)
	block.grid_position = final_position / GRID_SIZE

	block.create_tween().tween_property(block, "position", final_position, TWEEN_DURATION)

	selected_block = null


## Get a list of cells occupied by all blocks but the selected one.
func get_all_occupied_cells() -> Array[Vector2i]:
	var output: Array[Vector2i] = BOUNDARY_TILES
	for block in %Blocks.get_children() as Array[RushHourBlock]:
		if block != selected_block:
			output += block.get_occupied_cells()

	return output


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and selected_block != null:
		var mouse_pos := get_global_mouse_position()
		var occupied_cells := get_all_occupied_cells()
		var grid_pos := selected_block.grid_position
		if selected_block.direction == HORIZONTAL:
			var desired_position := block_initial_position + Vector2(mouse_pos.x - mouse_initial_position.x, 0)
			# Maximum and minimum range of tiles for this movement, inclusive.
			var min_x = min(grid_pos.x, floor(desired_position.x / GRID_SIZE))
			var max_x = max(grid_pos.x + selected_block.block_size - 1, floor(desired_position.x / GRID_SIZE) + selected_block.block_size)
			if desired_position.x < selected_block.position.x:
				# Go backwards (left) to find first tile that is occupied. Remember, inclusive range.
				for tile_x in range(max_x, min_x - 1, -1):
					if Vector2i(tile_x, grid_pos.y) in occupied_cells:
						# Add one to move the block outside the occupied tile.
						selected_block.position = Vector2i(tile_x + 1, grid_pos.y) * GRID_SIZE
						return
			else:
				# Go forwards (right) to find the first occupied tile.
				for tile_x in range(min_x, max_x + 1):
					if Vector2i(tile_x, grid_pos.y) in occupied_cells:
						print("Hit ", tile_x)
						# Subtract the block size to move the block outside the occupied tile
						selected_block.position = Vector2i(tile_x - selected_block.block_size, grid_pos.y) * GRID_SIZE
						return
			# We didn't hit any tiles.
			selected_block.position = desired_position
		else:
			var desired_position := block_initial_position + Vector2(0, mouse_pos.y - mouse_initial_position.y)
			var min_y = min(grid_pos.y, floor(desired_position.y / GRID_SIZE))
			var max_y = max(grid_pos.y + selected_block.block_size - 1, floor(desired_position.y / GRID_SIZE) + selected_block.block_size)
			if desired_position.y < selected_block.position.y:
				for tile_y in range(max_y, min_y - 1, -1):
					if Vector2i(grid_pos.x, tile_y) in occupied_cells:
						selected_block.position = Vector2i(grid_pos.x, tile_y + 1) * GRID_SIZE
						return
			else:
				for tile_y in range(min_y, max_y + 1):
					if Vector2i(grid_pos.x, tile_y) in occupied_cells:
						selected_block.position = Vector2i(grid_pos.x, tile_y - selected_block.block_size) * GRID_SIZE
						return
			selected_block.position = desired_position
