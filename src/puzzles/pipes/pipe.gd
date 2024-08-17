class_name Pipe
extends Sprite2D


enum {
	X_SHAPE,
	T_SHAPE,
	ELBOW,
	STRAIGHT,
}


const GRID_SIZE = 64


signal rotation_changed


var atlas: Texture2D

var type: int
var filled: bool = false
var grid_position: Vector2i


func setup(_type: int, rotation_deg: int, _grid_position: Vector2i):
	type = _type

	# Is there a better way?
	atlas = (texture as AtlasTexture).get_atlas()
	texture = AtlasTexture.new()
	texture.atlas = atlas
	texture.region = get_atlas_region()

	if rotation_deg not in [0, 90, 180, 270]:
		push_error("Invalid rotation")
	else:
		rotation_degrees = rotation_deg

	grid_position = _grid_position
	position = GRID_SIZE / 2.0 * Vector2.ONE + GRID_SIZE * Vector2(grid_position)


func get_atlas_region() -> Rect2:
	var output := Rect2()
	var y_offset := 16 if filled else 0
	match(type):
		X_SHAPE:
			output = Rect2(0, y_offset, 16, 16)
		T_SHAPE:
			output = Rect2(16, y_offset, 16, 16)
		ELBOW:
			output = Rect2(32, y_offset, 16, 16)
		STRAIGHT:
			output = Rect2(48, y_offset, 16, 16)
		_:
			push_error("Invalid pipe type")

	return output


func set_filled(_filled: bool) -> void:
	filled = _filled
	(texture as AtlasTexture).region = get_atlas_region()


## Get the connected directions.
func get_connected_directions() -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	var directions: Array[Vector2i] = []
	match(type):
		X_SHAPE:
			directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
		T_SHAPE:
			directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
		ELBOW:
			directions = [Vector2i.UP, Vector2i.RIGHT]
		STRAIGHT:
			directions = [Vector2i.RIGHT, Vector2i.LEFT]
		_:
			push_error("Invalid pipe type")

	for direction in directions:
		# There's gotta be a better way
		output.append(Vector2i(Vector2(direction).rotated(rotation)))

	return output


func on_button_pressed():
	print("Button pressed")
	if $AnimationPlayer.is_playing():
		return
	var initial_rotation = round(rotation_degrees)
	if initial_rotation == 0:
		print("0, 90")
		$AnimationPlayer.play("rotate_0_90")
	elif initial_rotation == 90:
		print("90, 180")
		$AnimationPlayer.play("rotate_90_180")
	elif initial_rotation == 180:
		print("180, 270")
		$AnimationPlayer.play("rotate_180_270")
	else:
		print("270, 0")
		$AnimationPlayer.play("rotate_270_0")

	await $AnimationPlayer.animation_finished

	rotation_degrees = fmod(initial_rotation + 90, 360.0)
	rotation_changed.emit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
