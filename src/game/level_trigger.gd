extends Area2D


@export var scene_to_load: PackedScene

var was_triggered := false


func on_body_entered(_body: Node2D) -> void:
	if was_triggered:
		return
	was_triggered = true
	var level_transition := owner.get_node("LevelTransition") as LevelTransition
	var player := get_tree().get_first_node_in_group("Player")
	player.freeze()
	if level_transition != null:
		level_transition.close()
		await level_transition.animation_finished
	get_tree().change_scene_to_packed(scene_to_load)
