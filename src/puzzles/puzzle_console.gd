extends CanvasLayer


signal puzzle_complete()


const PUZZLE_POSITION := Vector2(104, 104)


@onready var puzzle: Puzzle = $FlowPuzzle


func load_puzzle(puzzle_to_load: PackedScene) -> void:
	puzzle.load_puzzle(puzzle_to_load)
	puzzle.position = PUZZLE_POSITION


func reset_puzzle() -> void:
	puzzle.reset()


func on_puzzle_complete():
	puzzle_complete.emit()
