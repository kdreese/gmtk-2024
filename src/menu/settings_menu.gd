extends Control


signal go_back()

@onready var title: Label = $Title
@onready var back_button: Button = %BackButton

@onready var sound_slider: HSlider = %SoundSlider
@onready var sound_indicator: Label = %SoundIndicator
@onready var music_slider: HSlider = %MusicSlider
@onready var music_indicator: Label = %MusicIndicator

@onready var fullscreen_button: CheckButton = %FullscreenButton
@onready var speedrun_button: CheckButton = %SpeedrunButton

@onready var spacer2: Control = %Spacer2
@onready var quit_button: Button = %QuitButton

@onready var quit_dim_rect: ColorRect = $QuitDimRect
@onready var quit_dialog: ConfirmationDialog = $QuitDialog


func _ready() -> void:
	sound_slider.set_value_no_signal(Global.prefs["sound_volume"])
	sound_indicator.text = "%d%%" % [100 * Global.prefs["sound_volume"]]
	music_slider.set_value_no_signal(Global.prefs["music_volume"])
	music_indicator.text = "%d%%" % [100 * Global.prefs["music_volume"]]

	fullscreen_button.set_pressed_no_signal(Global.prefs["fullscreen"])
	speedrun_button.set_pressed_no_signal(Global.prefs["speedrun"])


func setup_pause_menu() -> void:
	title.text = "Paused"
	back_button.text = "Resume"
	spacer2.show()
	quit_button.show()


func _on_back_button_pressed() -> void:
	go_back.emit()


func _on_sound_slider_value_changed(value: float) -> void:
	# Just in case?
	value = clampf(value, 0.0, 1.0)
	sound_indicator.text = "%d%%" % [100 * value]
	Global.prefs["sound_volume"] = value
	Global.enact_prefs()


func _on_music_slider_value_changed(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	music_indicator.text = "%d%%" % [100 * value]
	Global.prefs["music_volume"] = value
	Global.enact_prefs()


func _on_fullscreen_button_toggled(toggled_on: bool) -> void:
	Global.prefs["fullscreen"] = toggled_on
	Global.enact_prefs()


func _on_speedrun_button_toggled(toggled_on: bool) -> void:
	Global.prefs["speedrun"] = toggled_on
	Global.enact_prefs()


func _on_quit_button_pressed() -> void:
	quit_dim_rect.show()
	quit_dialog.popup_centered()


func _on_quit_dialog_confirmed() -> void:
	SpeedrunTimer.quit_speedrun()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/menu/root_menu.tscn")


func _on_quit_dialog_canceled() -> void:
	quit_dim_rect.hide()
