extends StageBase

var can_drive:bool = true
var dancers:Array[LimoDancer] = []
func _ready():
	default_zoom = 0.9
	bf_pos = Vector2(1030, -120)
	bf_cam_offset.x = -200
	gf_pos.y = 120
	
	$Car.position.y = randi_range(220, 250)
	for i in 5: # fuck positioning things by hand
		var limo = $BGLimo/Sprite.position
		var new_dancer = LimoDancer.new(Vector2((370 * i) + 440 + limo.x, limo.y - 870))
		$BGLimo/LimoDancers.add_child(new_dancer)
		dancers.append(new_dancer)

func beat_hit(_beat:int) -> void:
	for dancer in dancers:
		dancer.dance()
	
	if can_drive and Game.rand_bool(10):
		move_child($Car, get_child_count())
		Audio.play_sound('carPass'+ str(randi_range(0, 1)), 0.7)
		$Car.velocity.x = (randi_range(170, 220) / 0.05) * 3
		can_drive = false
		await get_tree().create_timer(2).timeout
		$Car.velocity.x = 0
		$Car.position = Vector2(-12600, randi_range(220, 250))
		can_drive = true

class LimoDancer extends AnimatedSprite2D:
	var danced:bool = false
	func _init(pos:Vector2):
		centered = false
		position = pos
		sprite_frames = load('res://assets/images/stages/limo/limoDancer.res')
		frame = sprite_frames.get_frame_count('danceLeft') - 1
	
	func dance() -> void:
		danced = !danced
		play('dance'+ ('Right' if danced else 'Left'))
