class_name TextBox
extends CanvasLayer


signal line_finished()
signal text_finished()
signal next()


var skip_line: bool
var line_idx: int
var char_idx: int


func play(lines: Array[String]) -> void:
	if visible:
		# Don't play if we're already playing
		return
	show()
	line_idx = 0
	while line_idx < len(lines):
		var line := lines[line_idx]
		play_line(line)
		await line_finished
		await next
		line_idx += 1
	text_finished.emit()
	hide()


func play_line(line: String) -> void:
	$Panel/RichTextLabel.text = ""
	skip_line = false
	char_idx = 0
	$Timer.start()
	while char_idx < len(line) and not skip_line:
		await $Timer.timeout
		$Panel/RichTextLabel.text = line.substr(0, char_idx + 1)
		if line[char_idx] not in [" ", "\t", "\n"]:
			$TextSound.play()
		char_idx += 1

	$Timer.stop()
	$Panel/RichTextLabel.text = line
	line_finished.emit()


func skip_to_end_of_line() -> void:
	skip_line = true


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		next.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			next.emit()
			get_viewport().set_input_as_handled()
