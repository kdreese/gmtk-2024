extends Area2D


signal puzzle_complete()


## Which puzzle this terminal activates
@export var puzzle: PackedScene
## Dialog that is played before the puzzle starts
@export_multiline var dialog_before: Array[String]
## Dialog that is played after solving the puzzle
@export_multiline var dialog_after: Array[String]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_label: Label = $InteractLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _on_body_entered(_body: Node2D) -> void:
	interact_label.show()


func _on_body_exited(_body: Node2D) -> void:
	interact_label.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and interact_label.visible:
		collision_shape.disabled = true
		await owner.play_puzzle(puzzle, dialog_before, dialog_after)
		animated_sprite.play("on")
		puzzle_complete.emit()
