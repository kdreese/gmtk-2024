extends BaseLevel


@export var puzzle: PackedScene


func _ready() -> void:
	super._ready()
	$Terminal.interacted.connect(show_puzzle)
	$PuzzleConsole.puzzle_complete.connect(puzzle_completed)
	$LevelTransition.open()
	$EndTrigger.body_entered.connect(level_trigger_entered)


func show_puzzle() -> void:
	$Player.freeze()
	$PuzzleConsole.show()
	$PuzzleConsole.load_puzzle(puzzle)


func puzzle_completed() -> void:
	$Player.unfreeze()
	$PuzzleConsole.hide()
	$Door.open()


func level_trigger_entered(_body: Node2D) -> void:
	$LevelTransition.close()
	await $LevelTransition.animation_finished
	get_tree().change_scene_to_file("res://src/menu/root_menu.tscn")
