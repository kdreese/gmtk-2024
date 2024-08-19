extends CanvasLayer


func set_scroll_speeds(scroll_speed: float) -> void:
	for parallax_layer in $Layers.get_children() as Array[Parallax2D]:
		parallax_layer.autoscroll.y = scroll_speed * parallax_layer.scroll_scale.y
