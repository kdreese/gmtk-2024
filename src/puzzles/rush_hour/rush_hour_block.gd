@tool
class_name RushHourBlock
extends TextureRect

# TODO: Find a clean way to sync this from the grid scene.
const GRID_SIZE := 80

signal selected(block: RushHourBlock)
signal released(block: RushHourBlock)

enum {
	HORIZONTAL,
	VERTICAL,
}

@export_enum("Horizontal:0", "Vertical:1")
var direction: int

@export_range(2,3)
var block_size: int

@export var grid_position: Vector2i = Vector2i.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_block_size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		set_block_size()


func on_gui_input(input: InputEvent) -> void:
	if input is InputEventMouseButton:
		if input.button_index == MOUSE_BUTTON_LEFT:
			if input.pressed:
				selected.emit(self)
			else:
				released.emit(self)


func set_block_size() -> void:
	if direction == HORIZONTAL:
		size = Vector2(GRID_SIZE * block_size, GRID_SIZE)
	else:
		size = Vector2(GRID_SIZE, GRID_SIZE * block_size)
	position = Vector2(GRID_SIZE * grid_position)


func get_occupied_cells() -> Array[Vector2i]:
	var output : Array[Vector2i] = [grid_position]

	if direction == HORIZONTAL:
		for idx in range(1, block_size):
			output.append(grid_position + idx * Vector2i.RIGHT)
	else:
		for idx in range(1, block_size):
			output.append(grid_position + idx * Vector2i.DOWN)

	return output
