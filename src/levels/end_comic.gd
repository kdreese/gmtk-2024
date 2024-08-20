extends Node


@export var screen_shake_strength := 0.0

var pause_menu: Control
var camera_pos: Vector2
var can_exit_to_menu := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var screen_shake_timer: Timer = $ScreenShakeTimer


func _ready() -> void:
	camera_pos = camera.position
	spawn_pause_menu()
	animation_player.play("end_cutscene")
	await animation_player.animation_finished
	can_exit_to_menu = true


# From base_level.gd
func spawn_pause_menu() -> void:
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)
	pause_menu = preload("res://src/menu/settings_menu.tscn").instantiate()
	canvas_layer.add_child(pause_menu)
	pause_menu.setup_pause_menu()
	pause_menu.hide()
	pause_menu.go_back.connect(func(): pause_menu.hide(); get_tree().paused = false)


func _input(event: InputEvent) -> void:
	# From base_level.gd
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		pause_menu.show()
		(pause_menu.get_node("%BackButton") as Button).grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		if can_exit_to_menu:
			can_exit_to_menu = false
			animation_player.play("fade_out")
			get_viewport().set_input_as_handled()
			await animation_player.animation_finished
			get_tree().change_scene_to_file("res://src/menu/root_menu.tscn")



func _on_screen_shake_timer_timeout() -> void:
	var offset := Vector2(screen_shake_strength, 0.0)
	offset = offset.rotated(randf() * TAU)

	camera.position = camera_pos + offset

	if screen_shake_strength <= 0:
		screen_shake_timer.stop()
