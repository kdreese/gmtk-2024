extends StaticBody2D


func open() -> void:
	$AnimatedSprite2D.play("open")
	$CollisionShape2D.disabled = true
