extends Area2D


signal help_text_finished()


@export_multiline var dialog: Array[String] = []

@onready var interact_label: Label = $InteractLabel


func _on_body_entered(_body: Node2D) -> void:
	interact_label.show()


func _on_body_exited(_body: Node2D) -> void:
	interact_label.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and interact_label.visible:
		await owner.play_dialog(dialog)
		help_text_finished.emit()
