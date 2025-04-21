extends StageBase

var can_drive:bool = true
var star_offset:int = 2
var star_beat:int = 0

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

func post_ready() -> void:
	gf.reparent($FGLimo)
	gf.show_behind_parent = true
	
	var new = ShaderMaterial.new()
	new.shader = load('res://game/resources/shaders/adjust_color.gdshader')
	new.set_shader_parameter('hue', -30)
	new.set_shader_parameter('saturation', -20)
	new.set_shader_parameter('brightness', -30)
	
	var fucks = [boyfriend, gf, dad, $Car]
	fucks.append_array(dancers)
	for i in fucks:
		i.material = new
	
func beat_hit(beat:int) -> void:
	for dancer in dancers:
		dancer.dance()
	
	if can_drive and Util.rand_bool(10):
		move_child($Car, get_child_count())
		Audio.play_sound('carPass'+ str(randi_range(0, 1)), 0.7)
		$Car.velocity.x = (randi_range(170, 220) / 0.05) * 3
		can_drive = false
		await get_tree().create_timer(2).timeout
		$Car.velocity.x = 0
		$Car.position = Vector2(-12600, randi_range(220, 250))
		can_drive = true
	
	if Util.rand_bool(10) and beat > star_beat + star_offset:
		var le_star:AnimatedSprite2D = $Star/Sprite
		le_star.position.x = randi_range(50,900)
		le_star.position.y = randi_range(-10,20)
		le_star.flip_h = Util.rand_bool(50)
		le_star.play()

		star_beat = beat
		star_offset = randi_range(4, 8)
		
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
