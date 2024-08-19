extends CanvasLayer


signal animation_finished()


func _ready() -> void:
	$ColorRect/AnimationPlayer.play("RESET")


func open() -> void:
	$ColorRect/AnimationPlayer.play("open")


func close() -> void:
	$ColorRect/AnimationPlayer.play("close")


func on_animation_finished(_anim_name: String) -> void:
	animation_finished.emit()
