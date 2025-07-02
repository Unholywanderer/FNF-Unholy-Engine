extends AnimatedSprite2D

var should_scroll:bool:
	get: return $NameBox/Song.get_total_character_count() >= 18
func _process(delta:float) -> void:
	if should_scroll:
		$NameBox/Song.position
