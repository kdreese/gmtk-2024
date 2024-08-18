extends CenterContainer


signal show_credits()

@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	if OS.has_feature("web"):
		quit_button.hide()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/levels/level1.tscn")


func _on_credits_button_pressed() -> void:
	show_credits.emit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
