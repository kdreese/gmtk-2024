extends BaseLevel


@export var puzzle: PackedScene

@onready var terminal: Area2D = $Terminal
@onready var puzzle_console: CanvasLayer = $PuzzleConsole


func _ready() -> void:
	super._ready()
	terminal.interacted.connect(show_puzzle)
	puzzle_console.puzzle_complete.connect(puzzle_completed)


func show_puzzle() -> void:
	player.freeze()
	puzzle_console.show()
	puzzle_console.load_puzzle(puzzle)


func puzzle_completed() -> void:
	player.unfreeze()
	player.unlocked_double_jump = true
	puzzle_console.hide()
	terminal.turn_on()
