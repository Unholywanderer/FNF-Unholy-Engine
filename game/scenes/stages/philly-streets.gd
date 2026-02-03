extends StageBase

var light_stop:bool = false
var change_interval:int = 8
var prev_change:int = 0

var car_waiting:bool = false
var car1_interruptable:bool = true
var car2_interruptable:bool = true
var papr_interruptable:bool = true
const car_offsets = [[0, 0], [20, -15], [30, 50], [10, 60]]

@onready var spraycan:Atlas = $SprayCan
var CAN = load('res://assets/images/stages/philly-streets/effects/spraycanFULL.res')
func _ready() -> void:
	$Car1/Sprite.position = Vector2(1200, 818)
	$Car2/Sprite.position = Vector2(1200, 818)

	Main.cam.position = Vector2(400, 490)

func post_ready() -> void:
	#if SONG.player1.contains('pico') and !Main.GAME_OVER:
	#	Main.GAME_OVER = load('res://game/scenes/game_over-pico.tscn').instantiate()

	spraycan.add_anim_by_frames('kick_up', [0, 7])
	spraycan.add_anim_by_frames('kick_at', [8, 18])
	spraycan.add_anim_by_frames('bonk', [19, 24])
	spraycan.add_anim_by_frames('shot', [26, 44])
	spraycan.anim_changed.connect(func():
		if spraycan.cur_anim == 'bonk':
			spraycan.offset = Vector2(-240, -130)
			$Explosion.position = Vector2(1950, 820)
		else:
			spraycan.offset = Vector2(0, 0)
	)
	$Explosion.animation_finished.connect($Explosion.hide)
	spraycan.frame_changed.connect(func():
		if spraycan.frame == 22:
			$Explosion.show()
			$Explosion.play()
			$Explosion.frame = 0
	)
	spraycan.finished.connect(func():
		spraycan.visible = spraycan.cur_anim.begins_with('kick')
	)

	if Game.scene.story_mode:
		if Util.format_str(SONG.song) == 'darnell':
			var BITCH = ColorRect.new()
			BITCH.color = Color.BLACK
			BITCH.size = Vector2(1400, 800)
			UI.add_behind(BITCH)

			UI.toggle_objects(false)
			UI.pause_countdown = true
			Main.speaker.active = false
			Main.can_pause = false
			Main.lerp_zoom = false

			var cutscene := Cutscene.new()
			cutscene.play_video('darnellCutscene', true, false, UI.back)

			cutscene.video_finished.connect(func():
				var fucky = func(): dad.dance()
				var fucke = func(): gf.dance(); Main.speaker.bump()
				dad.animation_finished.connect(fucky)
				gf.animation_finished.connect(fucke)
				dad.dance()
				gf.dance()

				create_tween().tween_property(BITCH, 'modulate:a', 0, 1.5).set_delay(0.3).finished.connect(BITCH.queue_free)

				Main.cam.position_smoothing_enabled = false
				Main.move_cam(true)
				Main.cam.position.x += 250
				Main.cam.zoom = Vector2(1.3, 1.3)

				boyfriend.play_anim('intro')
				Main.speaker.look(true)

				cutscene.add_timed_event(0.7, func():
					Audio.play_music('darnellCanCutscene', false)
					cutscene.add_timed_event(Audio.track_length, func():
						UI.toggle_objects()
						create_tween().tween_property(Main.cam, 'zoom', Vector2(0.77, 0.77), 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)\
						 .finished.connect(func(): Main.lerp_zoom = true)
						UI.start_countdown(true)
						Main.can_pause = true
						Main.cam.position_smoothing_enabled = true
						Main.move_cam(false)
						Main.speaker.active = true

						dad.animation_finished.disconnect(fucky)
						gf.animation_finished.disconnect(fucke)
					)
				)
				var init_delay = 2.0
				cutscene.add_timed_event(init_delay, func():
					Main.speaker.look(false)
					#Main.move_cam(false)

					var new_cam_pos:Vector2 = (dad.get_cam_pos() + dad_cam_offset) + Vector2(100, 0)
					#Main.cam.position.x += 100
					var fuck = create_tween()
					fuck.tween_property(Main.cam, 'zoom', Vector2(0.66, 0.66), 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
					fuck.parallel().tween_property(Main.cam, 'position', new_cam_pos, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
					#moveCamera(true);
					#camFollow.x += 100;
					#FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 100 - FlxG.width/2, y: camFollow.y - FlxG.height/2}, 2.5, {ease: FlxEase.quadInOut});
				)
				cutscene.add_timed_event(init_delay + 3, func():
					dad.play_anim('light')
					dad.can_dance = false
					Audio.play_sound('weekend/lighter')
				)
				cutscene.add_timed_event(init_delay + 4, func():
					Main.speaker.look(true)
					boyfriend.play_anim('cock')
					Audio.play_sound('weekend/gun_prep')
					create_tween().tween_property(Main.cam, 'position:x', Main.cam.position.x + 180, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

					#FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 180 - FlxG.width/2}, 0.4, {ease: FlxEase.backOut});
				)
				#cutscene.add_timed_event(init_delay + 4.166, create_casing)
				cutscene.add_timed_event(init_delay + 4.5, func():
					dad.play_anim('kick')
					Audio.play_sound('weekend/kickUp')
					spraycan.visible = true
					spraycan.play_anim('kick_up')
				)
				cutscene.add_timed_event(init_delay + 4.8, func():
					dad.play_anim('knee')
					dad.can_dance = true
					Audio.play_sound('weekend/kickForward')
					spraycan.play_anim('kick_at')
				)
				cutscene.add_timed_event(init_delay + 5.1, func():
					boyfriend.play_anim('intro-return')
					create_tween().tween_property(Main.cam, 'position:x', Main.cam.position.x - 100, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
					#FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 100 - FlxG.width/2}, 2.5, {ease: FlxEase.quadInOut});
					Audio.play_sound('weekend/shots/'+ str(randi_range(1, 4)))
					spraycan.play_anim('shot')

	#				spraycan.playCanShot();
	#				new FlxTimer().start(1/24, function(_)
	#				{
	#					darkenStageProps();
	#				});
				)
				cutscene.add_timed_event(init_delay + 5.9, func():
					Main.speaker.look(false)
					get_tree().create_timer(0.1, false).timeout.connect(func(): dad.play_anim('laugh'))
					Audio.play_sound('weekend/cutscene/darnell_laugh')
				)
				cutscene.add_timed_event(init_delay + 6.2, func():
					gf.play_anim('laugh')
					Audio.play_sound('weekend/cutscene/nene_laugh')
				)
			)

func _process(delta:float) -> void:
	$Skybox/Sprite.region_rect.position.x -= delta * 22
	$Smog/Sprite.region_rect.position.x += delta * 22


func beat_hit(beat:int) -> void:
	var can_change:bool = (beat == (prev_change + change_interval))

	if Util.rand_bool(10) && !can_change && car1_interruptable:
		if !light_stop:
			pass #drive_car($Car1/Sprite)
		else:
			pass #drive_car_lights($Car1/Sprite)

	if (Util.rand_bool(10) && !can_change && car2_interruptable && !light_stop):pass
		#drive_car_back($Cars2)

	if can_change:
		change_lights(beat)

func change_lights(b:int) -> void:
	prev_change = b
	light_stop = !light_stop

	if light_stop:
		$Traffic/Sprite.play('to_red')
		change_interval = 20
	else:
		$Traffic/Sprite.play('to_green')
		change_interval = 30

		if car_waiting:
			pass #finish_car_lights($Car1/Sprite)


var cocked:bool = false
func good_note_hit(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	match note.type.replace('weekend-1-', ''):
		&'cockgun':
			cocked = true
			boyfriend.play_anim('cock' if boyfriend.cur_char == 'pico' else 'pre-attack', true)
			boyfriend.special_anim = true
			Audio.play_sound('weekend/gun_prep')
		&'firegun':
			if !cocked:
				note_miss(note)
				return
			cocked = false
			if Util.rand_bool(10) and boyfriend.cur_char == 'pico':
				boyfriend.play_anim('intro')
				boyfriend.frame = 34
				boyfriend.pause()

				spraycan.play_anim('bonk')
				spraycan.offset = Vector2(-350, -120)
				$Explosion.position = Vector2.INF
				Audio.play_sound('weekend/bonk')
			else:
				boyfriend.play_anim('shoot' if boyfriend.cur_char == 'pico' else 'attack', true)
				boyfriend.special_anim = true

				Audio.play_sound('weekend/shots/'+ str(randi_range(1, 4)))
				spraycan.play_anim('shot')

var died_by_can:bool = false
func note_miss(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	if note.type == 'weekend-1-firegun':
		Audio.play_sound('weekend/bonk')
		spraycan.play_anim('bonk')
		boyfriend.play_anim('shootMISS', true)
		boyfriend.special_anim = true

		UI.icon_p1.has_lose = false
		UI.icon_p1.frame = 1
		get_tree().create_timer(0.75, false).timeout.connect(func(): UI.icon_p1.has_lose = true)

		get_tree().create_timer(0.3).timeout.connect(func():
			Util.shake_obj(UI.health_bar, 8, 1, 'y')
			UI.hp -= 30
			died_by_can = UI.hp <= 0
		)


func opponent_note_hit(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	match note.type.replace('weekend-1-', ''):
		&'lightcan':
			dad.play_anim('light', true)
			dad.special_anim = true
			Audio.play_sound('weekend/lighter')
		&'kickcan' :
			dad.play_anim('kick', true)
			dad.special_anim = true
			spraycan.visible = true
			spraycan.play_anim('kick_up')
			Audio.play_sound('weekend/kickUp')
		&'kneecan' :
			dad.play_anim('knee', true)
			dad.special_anim = true
			spraycan.play_anim('kick_at')
			Audio.play_sound('weekend/kickForward')

func game_over_start():
	if died_by_can:
		Main.GAME_OVER.death_type = Main.GAME_OVER.TYPES.EXPLODE
