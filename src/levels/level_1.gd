extends BaseLevel


@export var puzzle: PackedScene


func _ready() -> void:
	super._ready()
	$Terminal.interacted.connect(show_puzzle)
	$HelpPoint.interacted.connect(play_text_box.bind($TextBox))
	$PuzzleConsole.puzzle_complete.connect(puzzle_completed)


func show_puzzle() -> void:
	$Player.freeze()
	$PuzzleConsole.show()
	await $PuzzleConsole.load_puzzle(puzzle)
	play_text_box($TextBox)


func puzzle_completed() -> void:
	$Player.unfreeze()
	$PuzzleConsole.hide()
	$Door.open()
	$Terminal.turn_on()
