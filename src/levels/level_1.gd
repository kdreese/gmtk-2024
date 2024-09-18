extends BaseLevel


func _ready() -> void:
	super._ready()
	SpeedrunTimer.start_speedrun()


func puzzle_completed() -> void:
	$Door.open()
