extends StageBase

var tank_notes:Array = [] # for the fucks that run in and get shot
var runnin_boys:Array = []
func _ready():
	$Clouds/Sprite.moving = true
	$Clouds/Sprite.position = Vector2(randi_range(-700, -100), randi_range(-20, -20))
	$Clouds/Sprite.velocity.x = randf_range(5, 15)

	$Tank.add_child(TankBG.new())

func post_ready() -> void:
	if true:
		dad.hide()
		UI.toggle_objects(false)
		UI.pause_countdown = true
		Main.can_pause = false
		Main.lerp_zoom = false

		Audio.play_music('DISTORTO')
		var tank = $CharGroup/Tanky
		var cutscene := Cutscene.new()
		cutscene.finished.connect(func():
			Audio.stop_music(true)
			UI.toggle_objects(true)
			UI.start_countdown(true)
			Main.can_pause = true
			Main.lerp_zoom = true
			tank.queue_free()
			dad.show()
		)
		match SONG.song.to_lower():
			'ugh':
				cutscene.max_time = 12
				tank.position = dad.position - Vector2(310, 830)
				#tank.add_anim_by_symbol('well', 'TANK TALK 1 P1')
				tank.add_anim_by_frames('well', [0, 80])
				#tank.add_anim_by_symbol('kill', 'TANK TALK 2 P1')
				tank.add_anim_by_frames('kill', [76, 226])

				cutscene.add_timed_event(0.1, func():
					Audio.play_sound('tank/cutscene/wellWellWell')
					tank.play_anim('well', true)
				)
				cutscene.add_timed_event(3, func(): Main.move_cam(true))
				cutscene.add_timed_event(4.5, func():
					boyfriend.sing(2)
					Audio.play_sound('tank/cutscene/bfBeep')
				)
				cutscene.add_timed_event(6, func():
					Main.move_cam(false)
					Audio.play_sound('tank/cutscene/killYou')
					tank.play_anim('kill', true)
				)
		pass

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
func beat_hit(_beat:int):
	for tank in $Forground.get_children():
		tank.get_node('Sprite').frame = 0
		tank.get_node('Sprite').play('idle')
	$Watchtower/Sprite.frame = 0
	$Watchtower/Sprite.play('idle')

func game_over_idle():
	var rand_line:String = str(randi_range(1, 25))
	var sub:String = JsonHandler.parse('data/tank-gameover_subs')[rand_line]

	var ass = load('res://game/objects/ui/subtitle.tscn').instantiate() #Util.quick_label(sub)
	ass.text = sub
	ass.icon = 'tankman'
	Main.GAME_OVER.add_over(ass)
	Util.center_obj(ass)
	ass.modulate.a = 0
	Util.quick_tween(ass, 'modulate:a', 1, 0.15, 'quad', 'in')

	#ass.position.x = 0
	ass.position.y += 250

	Audio.volume = 0.4
	var died := Audio.return_sound('tank/jeffGameover-'+ rand_line)
	died.finished.connect(func():
		Audio.volume = 1.0
		Util.quick_tween(ass, 'position:y', 800, 0.6, 'circ', 'in').finished.connect(ass.queue_free)
		Util.quick_tween(ass, 'modulate:a', 0, 0.53, 'quad', 'in')
	)
	died.play()

class TankBG extends AnimatedSprite2D:
	var off:Vector2 = Vector2(700, 1300)
	var speed:float = 0.0
	var angle:float = 0.0
	func _init() -> void:
		centered = false
		sprite_frames = load('res://assets/images/stages/tank/tankRolling.res')
		play('idle')
		speed = randf_range(5, 7)
		angle = randi_range(-90, 45)

	func _process(delta:float) -> void:
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

	func _init(pos:Vector2, right:bool) -> void:
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
		animation_finished.connect(queue_free)

	func reset(pos:Vector2, right:bool) -> void:
		position = pos
		facing_right = right
		ending_offset = randi_range(50, 200)
		t_speed = randf_range(0.6, 1)

	func _process(_delta:float) -> void:
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
