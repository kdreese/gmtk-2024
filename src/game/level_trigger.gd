extends Area2D


@export var scene_to_load: PackedScene


func on_body_entered(_body: Node2D) -> void:
	var level_transition := owner.get_node("LevelTransition") as LevelTransition
	if level_transition != null:
		level_transition.close()
		await level_transition
	get_tree().change_scene_to_packed(scene_to_load)
