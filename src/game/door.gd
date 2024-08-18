extends StaticBody2D


func _ready() -> void:
	$AnimatedSprite2D.play("default")


func open() -> void:
	$AnimatedSprite2D.play("open")
	$CollisionShape2D.disabled = true
