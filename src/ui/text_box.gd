extends CanvasLayer


signal line_finished()
signal text_finished()
signal next()


@export var dialog: Dialog

var skip_line: bool
var line_idx: int
var char_idx: int


func play() -> void:
	if visible:
		# Don't play if we're already playing
		return
	show()
	line_idx = 0
	while line_idx < len(dialog.lines):
		play_line()
		await line_finished
		await next
		line_idx += 1
	text_finished.emit()
	hide()


func play_line() -> void:
	$Panel/RichTextLabel.text = ""
	skip_line = false
	char_idx = 0
	var current_line := dialog.lines[line_idx]
	$Timer.start()
	while char_idx < len(current_line) and not skip_line:
		await $Timer.timeout
		$Panel/RichTextLabel.text = dialog.lines[line_idx].substr(0, char_idx + 1)
		if current_line[char_idx] not in [" ", "\t", "\n"]:
			$TextSound.play()
		char_idx += 1

	$Timer.stop()
	$Panel/RichTextLabel.text = current_line
	line_finished.emit()


func skip_to_end_of_line() -> void:
	if line_idx < len(dialog.lines) and char_idx < len(dialog.lines[line_idx]):
		skip_line = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		next.emit()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			next.emit()
