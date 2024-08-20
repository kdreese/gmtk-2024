class_name PuzzleConsole
extends CanvasLayer


signal puzzle_complete()


const PUZZLE_POSITION := Vector2(104, 104)


@onready var puzzle: Puzzle = $FlowPuzzle


func load_puzzle(puzzle_to_load: PackedScene) -> void:
	puzzle.load_puzzle(puzzle_to_load)
	puzzle.position = PUZZLE_POSITION + Vector2(0, 720)
	puzzle.show()
	var tween := create_tween()
	tween.tween_property($ColorRect, "modulate", Color.WHITE, 0.1)
	tween.tween_property($Sprite2D, "position", Vector2(640, 360), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(puzzle, "position", PUZZLE_POSITION, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	$Button.show()


func reset_puzzle() -> void:
	puzzle.reset()


func on_puzzle_complete():
	$Button.hide()
	var tween = create_tween()
	tween.tween_property($Sprite2D, "position", Vector2(640, 1080), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(puzzle, "position", PUZZLE_POSITION + Vector2(0, 720), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($ColorRect, "modulate", Color.TRANSPARENT, 0.1)
	await tween.finished
	puzzle_complete.emit()
