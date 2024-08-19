extends BaseLevel


@export var puzzle: PackedScene


func _ready() -> void:
	super._ready()
	$Terminal.interacted.connect(show_puzzle)
	$HelpPoint.interacted.connect(play_text)
	$PuzzleConsole.puzzle_complete.connect(puzzle_completed)


func play_text():
	$Player.freeze()
	$TextBox.play()
	await $TextBox.text_finished
	$Player.unfreeze()


func show_puzzle() -> void:
	$Player.freeze()
	$PuzzleConsole.show()
	$PuzzleConsole.load_puzzle(puzzle)


func puzzle_completed() -> void:
	$Player.unfreeze()
	$PuzzleConsole.hide()
	$Door.open()
	$Terminal.turn_on()
