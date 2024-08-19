extends Area2D


signal interacted()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_label: Label = $InteractLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func turn_off() -> void:
	animated_sprite.play("off")


func turn_on() -> void:
	animated_sprite.play("on")


func _on_body_entered(_body: Node2D) -> void:
	interact_label.show()


func _on_body_exited(_body: Node2D) -> void:
	interact_label.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and interact_label.visible:
		interacted.emit()
		collision_shape.disabled = true
