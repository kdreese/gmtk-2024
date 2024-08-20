extends BaseLevel


@onready var fade_animation: AnimationPlayer = %FadeAnimation


func _ready() -> void:
	super._ready()

	# Stationary camera
	var camera := player.get_node("Camera2D")
	player.remove_child(camera)
	add_child(camera)


func _on_help_point_help_text_finished() -> void:
	player.freeze()
	fade_animation.play("fade_out")
	await fade_animation.animation_finished
	get_tree().change_scene_to_file("res://src/levels/end_comic.tscn")
