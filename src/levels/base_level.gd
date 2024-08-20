## Base Level class
class_name BaseLevel
extends Node2D


var pause_menu: Control


func _ready() -> void:
	spawn_camera()
	spawn_level_transition()
	spawn_pause_menu()


func spawn_camera() -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")

	var camera_bounds := Rect2i()

	for tiles: TileMapLayer in get_tree().get_nodes_in_group("Tiles"):
		camera_bounds = camera_bounds.merge(tiles.get_used_rect())

	var camera := Camera2D.new()
	camera.zoom = Vector2(4.0, 4.0)
	camera.limit_left = camera_bounds.position.x * 16
	camera.limit_top = camera_bounds.position.y * 16
	camera.limit_right = camera_bounds.end.x * 16
	camera.limit_bottom = camera_bounds.end.y * 16
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS

	player.add_child(camera)


func spawn_level_transition():
	var level_transition := preload("res://src/ui/level_transition.tscn").instantiate()
	add_child(level_transition)
	level_transition.open()


func spawn_pause_menu() -> void:
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)
	pause_menu = preload("res://src/menu/settings_menu.tscn").instantiate()
	canvas_layer.add_child(pause_menu)
	pause_menu.setup_pause_menu()
	pause_menu.hide()
	pause_menu.go_back.connect(func(): pause_menu.hide(); get_tree().paused = false)


func play_text_box(text_box: TextBox) -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")
	player.freeze()
	text_box.play()
	await text_box.text_finished
	player.unfreeze()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		pause_menu.show()
		(pause_menu.get_node("%BackButton") as Button).grab_focus()
