extends BaseLevel


@export var puzzle: PackedScene


func _ready() -> void:
	super._ready()
	$Terminal.interacted.connect(show_puzzle)
	$PuzzleConsole.puzzle_complete.connect(puzzle_completed)


func show_puzzle() -> void:
	$Player.freeze()
	$PuzzleConsole.show()
	$PuzzleConsole.load_puzzle(puzzle)


func puzzle_completed() -> void:
	$Player.unfreeze()
	$PuzzleConsole.hide()
	$Door.open()
	$Terminal.turn_on()
