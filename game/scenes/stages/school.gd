extends StageBase

var bg_freaks = BGFreaks.new()
func _ready():
	#$FGTrees/Sprite.play()
	#$Petals/Sprite.play()
	default_zoom = 1.05
	bf_pos = Vector2(770, 90)
	dad_pos = Vector2(100, 30)
	gf_pos = Vector2(400, 130)

	bf_cam_offset.y = 100

	bg_freaks.position = Vector2(-100, 190)
	bg_freaks.scale *= Vector2(6, 6)
	if JsonHandler._SONG.song.to_lower().contains('roses'): bg_freaks.swapped = true

	bg_freaks.dance() #update their animation, then stop
	bg_freaks.stop()
	add_child(bg_freaks)

func beat_hit(beat:int):
	bg_freaks.dance()

class BGFreaks extends AnimatedSprite2D:
	var danced:bool = false
	var swapped:bool = false
	var frame_limit:int = 0

	func _init():
		centered = false
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite_frames = load('res://assets/images/stages/school/bgFreaks.res')

	func _process(_delta):
		if frame >= frame_limit:
			pause()

	func dance() -> void:
		danced = !danced
		frame_limit = 14 if danced else 29

		frame = 0 if frame_limit == 14 else 15
		play('BG '+ ('girls group' if !swapped else 'fangirls dissuaded'))
