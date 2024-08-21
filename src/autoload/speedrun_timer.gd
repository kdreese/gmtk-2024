## Speedrun mode because I like speedruns
extends CanvasLayer


var is_in_game := false
var is_running := false
var is_loading := false
var speedrun_ticks := 0

@onready var timer_label: Label = $TimerLabel


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	update_label_visibility()


func _physics_process(_delta: float) -> void:
	if is_running and not is_loading:
		speedrun_ticks += 1
		update_label_text()


func start_speedrun() -> void:
	is_running = true
	is_in_game = true
	is_loading = false
	update_label_visibility()
	update_label_text()


func start_loading() -> void:
	is_loading = true


func stop_loading() -> void:
	is_loading = false


func finish_speedrun() -> void:
	is_running = false
	update_label_text()


func quit_speedrun() -> void:
	is_running = false
	is_in_game = false
	update_label_visibility()


func update_label_text() -> void:
	var sub_second := speedrun_ticks % Engine.physics_ticks_per_second
	@warning_ignore("integer_division")
	var total_seconds := speedrun_ticks / Engine.physics_ticks_per_second
	var seconds := total_seconds % 60
	@warning_ignore("integer_division")
	var total_minutes := total_seconds / 60
	var minutes := total_minutes % 60
	# No way this gets used lmao
	@warning_ignore("integer_division")
	var hours := total_minutes / 60

	var text := "%02d:%02d.%03d" % [minutes, seconds, floor(1000 * (float(sub_second) / float(Engine.physics_ticks_per_second)))]
	if hours > 0:
		text = "%d:%s" % [hours, text]
	if not is_running:
		text = "%s Final Time" % [text]

	timer_label.text = text


func update_label_visibility() -> void:
	if is_in_game and Global.prefs["speedrun"]:
		timer_label.show()
	else:
		timer_label.hide()
