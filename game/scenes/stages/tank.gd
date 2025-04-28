extends StageBase

var tank_notes:Array = [] # for the fucks that run in and get shot
var runnin_boys:Array = []
func _ready():
	$Clouds/Sprite.moving = true
	$Clouds/Sprite.position = Vector2(randi_range(-700, -100), randi_range(-20, -20))
	$Clouds/Sprite.velocity.x = randf_range(5, 15)

	var tank_boy = TankBG.new()
	$Tank.add_child(tank_boy)

func init_tankmen():
	gf.chart = Chart.load_named_chart(JsonHandler.song_root, 'picospeaker', 'v_slice')
	tank_notes = gf.chart.duplicate()

	for note in tank_notes:
		if Util.rand_bool(16):
			var tankyboy = Tankmen.new(Vector2(500, 240 + randi_range(10, 50)), note[1] < 2)
			tankyboy.strum_time = note[0]
			$RunMen.add_child(tankyboy)
			runnin_boys.append(tankyboy)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func beat_hit(beat:int):
	for tank in $Forground.get_children():
		tank.get_node('Sprite').frame = 0
		tank.get_node('Sprite').play('idle')
	$Watchtower/Sprite.frame = 0
	$Watchtower/Sprite.play('idle')

var played_line:bool = false
func game_over_start(scene): played_line = false
func game_over_idle(scene):
	if !played_line:
		played_line = true
		Audio.volume = 0.4
		Audio.play_sound('tank/jeffGameover-'+ str(randi_range(1, 25)))


class TankBG extends AnimatedSprite2D:
	var off = Vector2(700, 1300)
	var speed:float = 0.0
	var angle:float = 0.0
	func _init():
		centered = false
		sprite_frames = load('res://assets/images/stages/tank/tankRolling.res')
		play('idle')
		speed = randf_range(5, 7)
		angle = randi_range(-90, 45)

	func _process(delta):
		angle += delta * speed
		rotation = deg_to_rad(angle - 90 + 15)
		position.x = off.x + 1500 * cos(PI / 180 * (angle + 180))
		position.y = off.y + 1100 * sin(PI / 180 * (angle + 180))

class Tankmen extends AnimatedSprite2D:
	var t_speed:float = 0.0
	var strum_time:float = 0.0
	var facing_right:bool = false
	var ending_offset:int = 0
	var shot_offset:Vector2 = Vector2(-400, -200)
	func fin(): queue_free()

	func _init(pos:Vector2, right:bool):
		centered = false
		position = pos
		sprite_frames = load('res://assets/images/stages/tank/tankmen/tankmanKilled1.res')
		scale = Vector2(0.8, 0.8)
		ending_offset = randi_range(50, 200)

		t_speed = randf_range(0.6, 1)

		facing_right = right
		if !facing_right:
			shot_offset.x /= 2
			shot_offset.x += 10
		play('runIn')
		frame = randi_range(0, sprite_frames.get_frame_count('runIn') - 1)
		animation_finished.connect(fin)

	func reset(pos:Vector2, right:bool):
		position = pos
		facing_right = right
		ending_offset = randi_range(50, 200)
		t_speed = randf_range(0.6, 1)

	func _process(delta):
		flip_h = facing_right

		if animation == 'runIn':
			var speed:float = (Conductor.song_pos - strum_time) * t_speed
			if facing_right:
				position.x = (0.02 * Game.screen[0] - ending_offset) + speed
			else:
				position.x = (0.74 * Game.screen[0] + ending_offset) - speed

		if Conductor.song_pos > strum_time:
			play('shot'+ str(randi_range(1, 2)))
			offset = shot_offset
			strum_time = INF
