extends StageBase

func _ready():
	default_zoom = 0.8
	bf_pos = Vector2(970, 100)
	gf_pos = Vector2(650, 100)
	
	bf_cam_offset = Vector2(-50, -100)
	
func beat_hit(_beat:int):
	for i in [$UpperBop/Sprite, $BottomBop, $Santa]:
		i.play()
		i.frame = 0
