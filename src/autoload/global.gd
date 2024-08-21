extends Node


const PREFS_FILE := "user://prefs.json"

const DEFAULT_PREFS := {
	"sound_volume": 0.5,
	"music_volume": 0.3,
	"fullscreen": false,
	"speedrun": false,
}

var prefs: Dictionary


func _ready() -> void:
	load_prefs()
	process_cmdline_args()
	enact_prefs()


func load_prefs() -> void:
	prefs = DEFAULT_PREFS.duplicate()

	var f := FileAccess.open(PREFS_FILE, FileAccess.READ)
	if f == null:
		var err := FileAccess.get_open_error()
		if err == ERR_FILE_NOT_FOUND:
			print("No save file, creating one")
			save_prefs()
		else:
			push_error("Could not open save file! %s" % [error_string(err)])
		return

	var text := f.get_as_text()
	f.close()

	var json = JSON.parse_string(text)
	if typeof(json) != TYPE_DICTIONARY:
		push_error("Invalid prefs file!!")
		return

	for property in prefs.keys():
		if json.has(property) and typeof(prefs[property]) == typeof(json[property]):
			prefs[property] = json[property]

	# Sanitize
	prefs["sound_volume"] = clampf(prefs["sound_volume"], 0.0, 1.0)
	prefs["music_volume"] = clampf(prefs["music_volume"], 0.0, 1.0)


func enact_prefs() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear_to_db(prefs["sound_volume"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(prefs["music_volume"]))

	var window := get_window()
	var is_fullscreen := window.mode == Window.MODE_FULLSCREEN
	if prefs["fullscreen"] != is_fullscreen:
		window.mode = Window.MODE_FULLSCREEN if prefs["fullscreen"] else Window.MODE_WINDOWED

	SpeedrunTimer.update_label_visibility()


func save_prefs() -> void:
	var f := FileAccess.open(PREFS_FILE, FileAccess.WRITE)
	if f == null:
		var err := FileAccess.get_open_error()
		push_error("Could not open prefs file for writing!! %s" % [error_string(err)])
		return

	var json := JSON.stringify(prefs, "\t", false)
	f.store_string(json)

	f.close()


func process_cmdline_args() -> void:
	if "--gotta-robot-fast" in OS.get_cmdline_user_args():
		prefs["speedrun"] = true



func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_prefs()
		get_tree().quit()
