extends StageBase

#var tank_notes:Array = [] # for the fucks that run in and get shot
var runnin_boys:Array = []
func _ready():
	$Clouds/Sprite.moving = true
	$Clouds/Sprite.position = Vector2(randi_range(-700, -100), randi_range(-20, -20))
	$Clouds/Sprite.velocity.x = randf_range(5, 15)

	$Tank.add_child(TankBG.new())

func countdown_start() -> void:
	if !Main.story_mode:
		$CharGroup/Tanky.queue_free()
		return

	if !Game.persist.get('seen_cutscene'):
		Game.persist.set('seen_cutscene', true)
		dad.hide()
		UI.toggle_objects(false)
		UI.pause_countdown = true
		Main.move_cam(false)
		Main.can_pause = false
		Main.lerp_zoom = false

		Audio.play_music('DISTORTO')
		var tank:Atlas = $CharGroup/Tanky
		tank.show()
		if tank._added_anims.is_empty():
			tank.add_anim_by_frames('well', [0, 80])
			tank.add_anim_by_frames('kill', [76, 226])
			tank.add_anim_by_frames('bars', [227, 506])
			tank.add_anim_by_frames('god', [507, 915])
			tank.add_anim_by_frames('school', [916, 1276])

		var cutscene := Cutscene.new()
		cutscene.finished.connect(func():
			Audio.stop_music(true)
			UI.toggle_objects(true)
			UI.start_countdown(true)
			Main.can_pause = true
			Main.lerp_zoom = true
			tank.hide()#queue_free()
			dad.show()
		)
		tank.position = dad.position - Vector2(310, 830)

		match SONG.song.to_lower():
			'ugh':
				cutscene.max_time = 12

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
			'guns':
				cutscene.max_time = 11.5

				tank.play_anim('bars', true)

				Audio.play_sound('tank/cutscene/tankSong2')
				var ne_z = Vector2(default_zoom * 1.2, default_zoom * 1.2)
				Util.quick_tween(Main.cam, 'zoom', ne_z, 4, 'quad', 'inout').set_delay(0)
				Util.quick_tween(Main.cam, 'zoom', ne_z * 1.2, 0.5, 'quad', 'inout').set_delay(4)
				Util.quick_tween(Main.cam, 'zoom', ne_z, 1, 'quad', 'inout').set_delay(4.5)
				cutscene.add_timed_event(4, func():	gf.play_anim('sad'))
			'stress':
				cutscene.max_time = 35.5
				Main.speaker.frame = 4

				boyfriend.hide()
				gf.hide()
				boyfriend.z_index = 2

				var funny_bf = AnimatedSprite2D.new()
				funny_bf.sprite_frames = load('res://assets/images/characters/bf/char.res')
				funny_bf.centered = false
				funny_bf.position = boyfriend.position + Vector2(5, 20)
				funny_bf.play('idle')
				funny_bf.frame = 13
				$CharGroup.add_child(funny_bf)
				funny_bf.z_index = 2

				var pico := Atlas.new()
				pico.atlas = 'res://assets/images/stages/tank/cutscenes/stressPico'
				pico.position = gf.position + Vector2(180, 347)
				$CharGroup.add_child(pico)

				pico.add_anim_by_frames('dance', [0, 29], 24, true)
				pico.add_anim_by_frames('dieBitch', [30, 82])
				pico.add_anim_by_frames('picoAppears', [83, 154])
				pico.add_anim_by_frames('picoEnd', [155, 182])

				pico.play_anim('dance', true)
				pico.frame_changed.connect(func():
					if pico.frame == 87:
						funny_bf.queue_free()
						boyfriend.show()
						boyfriend.play_anim('bfCatch')
						await get_tree().create_timer(1.3, false).timeout
						boyfriend.dance()
						boyfriend.frame = 13
				)
				pico.finished.connect(func():
					match pico.cur_anim:
						'dieBitch': pico.play_anim('picoAppears')
						'picoAppears': pico.play_anim('picoEnd')
						'picoEnd':
							pico.queue_free()
							gf.show()
							gf.play_anim('shootRight1-loop')
							boyfriend.z_index = 0
				)

				Audio.stop_music()
				Audio.play_sound('tank/cutscene/stressCutscene')
				tank.play_anim('god', true)

				cutscene.add_timed_event(15.2, func():
					Util.quick_tween(Main.cam, 'position', Vector2(650, 300), 1, 'sine', 'out')
					Util.quick_tween(Main.cam, 'zoom', Vector2(1.3, 1.3), 2.25, 'quad', 'inout')
					if pico: pico.play_anim('dieBitch', true)
				)

				cutscene.add_timed_event(17.5, func():
					Main.cam.position_smoothing_enabled = false
					Main.cam.position = Vector2(630, 425)
					Main.cam.zoom = Vector2(0.8, 0.8)
				)

				cutscene.add_timed_event(19.5, func(): tank.play_anim('school', true))
				cutscene.add_timed_event(20, func():
					Main.cam.position_smoothing_enabled = true
					Main.cam.position = dad.get_cam_pos() + Vector2(100, 0)
				)
				cutscene.add_timed_event(31.2, func():
					boyfriend.sing(0, 'miss')
					boyfriend.special_anim = true
				)

func init_tankmen():
	gf.chart = Chart.load_named_chart(JsonHandler.song_root, 'picospeaker', 'v_slice')
	#tank_notes = gf.chart.duplicate()

	for note in gf.chart:
		if Util.rand_bool(16):
			var tankyboy = Tankmen.new(Vector2(500, 240 + randi_range(10, 50)), note.dir < 2)
			tankyboy.strum_time = note.strum_time
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
	var sub:String = JsonHandler.parse('data/tank_subs')[rand_line]

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
	var died := Audio.return_sound('tank/gameover/jeffGameover-'+ rand_line)
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
		hide()

	func reset(pos:Vector2, right:bool) -> void:
		position = pos
		facing_right = right
		ending_offset = randi_range(50, 200)
		t_speed = randf_range(0.6, 1)

	func _process(_delta:float) -> void:
		visible = abs(Conductor.song_pos - strum_time) < (1000 / t_speed) or animation != 'runIn'
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
