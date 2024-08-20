## Base Level class
class_name BaseLevel
extends Node2D


@export var should_spawn_background := true

var player: Player
var pause_menu: Control
var text_box: TextBox
var puzzle_console: PuzzleConsole


func _ready() -> void:
	spawn_camera()
	if should_spawn_background:
		spawn_background()
	spawn_puzzle_console()
	spawn_text_box()
	spawn_pause_menu()
	spawn_spikes()
	spawn_level_transition()


func play_dialog(lines: Array[String], freeze_unfreeze := true) -> void:
	if not lines or lines.is_empty():
		return
	if freeze_unfreeze:
		player.freeze()
	text_box.play(lines)
	await text_box.text_finished
	if freeze_unfreeze:
		player.unfreeze()


func play_puzzle(puzzle: PackedScene, dialog_before: Array[String] = []) -> void:
	player.freeze()
	puzzle_console.show()
	await puzzle_console.load_puzzle(puzzle)
	@warning_ignore("redundant_await")
	await play_dialog(dialog_before, false)
	await puzzle_console.puzzle_complete
	puzzle_console.hide()
	player.unfreeze()


func spawn_camera() -> void:
	player = get_tree().get_first_node_in_group("Player")

	var camera_bounds := Rect2i()

	for tiles: TileMapLayer in get_tree().get_nodes_in_group("Tiles"):
		camera_bounds = camera_bounds.merge(tiles.get_used_rect())

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(4.0, 4.0)
	camera.limit_left = camera_bounds.position.x * 16
	camera.limit_top = camera_bounds.position.y * 16
	camera.limit_right = camera_bounds.end.x * 16
	camera.limit_bottom = camera_bounds.end.y * 16
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS

	player.add_child(camera)
	player.freeze()


func spawn_level_transition():
	var level_transition := preload("res://src/ui/level_transition.tscn").instantiate()
	add_child(level_transition)
	level_transition.open()
	await level_transition.animation_finished
	player.unfreeze()


func spawn_pause_menu() -> void:
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)
	pause_menu = preload("res://src/menu/settings_menu.tscn").instantiate()
	canvas_layer.add_child(pause_menu)
	pause_menu.setup_pause_menu()
	pause_menu.hide()
	pause_menu.go_back.connect(func(): pause_menu.hide(); get_tree().paused = false)


func spawn_spikes() -> void:
	var spikes_layer := get_node_or_null("Tiles/LayerHazard") as TileMapLayer
	if spikes_layer:
		var tiles := spikes_layer.get_used_cells_by_id(0, Vector2i(0,0))
		for tile in tiles:
			var spikes_pos := tile * 16
			var spikes := preload("res://src/game/spike_collision_area.tscn").instantiate()
			spikes.position = spikes_pos
			add_child(spikes)


func spawn_text_box() -> void:
	text_box = preload("res://src/ui/text_box.tscn").instantiate()
	add_child(text_box)
	text_box.hide()


func spawn_puzzle_console() -> void:
	puzzle_console = preload("res://src/puzzles/puzzle_console.tscn").instantiate()
	add_child(puzzle_console)
	puzzle_console.hide()


func spawn_background() -> void:
	add_child(preload("res://src/levels/parallax_background.tscn").instantiate())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		pause_menu.show()
		(pause_menu.get_node("%BackButton") as Button).grab_focus()
		get_viewport().set_input_as_handled()
