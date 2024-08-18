## Base Level class
class_name BaseLevel
extends Node2D


func _ready() -> void:
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

	$Terminal.interacted.connect(show_puzzle)
	$PuzzleConsole.puzzle_complete.connect(puzzle_completed)

	player.add_child(camera)


func show_puzzle() -> void:
	$PuzzleConsole.show()
	$PuzzleConsole.load_puzzle(preload("res://src/puzzles/flow/flow_puzzle_1.tscn"))


func puzzle_completed() -> void:
	$PuzzleConsole.hide()
	$Door.open()
