extends BaseLevel


@onready var fade_animation: AnimationPlayer = %FadeAnimation
@onready var help_point: Area2D = $HelpPoint


func _ready() -> void:
	super._ready()

	# Stationary camera
	var camera := player.get_node("Camera2D")
	player.remove_child(camera)
	add_child(camera)


func _on_help_point_help_text_finished() -> void:
	player.freeze()
	help_point.get_node("CollisionShape2D").disabled = true
	fade_animation.play("fade_out")
	SpeedrunTimer.finish_speedrun()
	await fade_animation.animation_finished
	get_tree().change_scene_to_file("res://src/levels/end_comic.tscn")
