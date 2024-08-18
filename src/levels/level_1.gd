extends BaseLevel


@export var puzzle: PackedScene


func _ready() -> void:
	super._ready()
	$Terminal.interacted.connect(show_puzzle)
	$PuzzleConsole.puzzle_complete.connect(puzzle_completed)


func show_puzzle() -> void:
	$PuzzleConsole.show()
	$PuzzleConsole.load_puzzle(puzzle)


func puzzle_completed() -> void:
	$PuzzleConsole.hide()
	$Door.open()
