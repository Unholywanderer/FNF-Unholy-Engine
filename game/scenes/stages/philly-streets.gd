extends StageBase

var light_stop:bool = false
var change_interval:int = 8
var prev_change:int = 0

var car_waiting:bool = false
var car1_interruptable:bool = true
var car2_interruptable:bool = true
var papr_interruptable:bool = true
const car_offsets = [[0, 0], [20, -15], [30, 50], [10, 60]]

@onready var cur_can:AnimateSymbol = $SprayCan
var CAN = load('res://assets/images/stages/philly-streets/effects/spraycanFULL.res')
func _ready() -> void:
	$Car1/Sprite.position = Vector2(1200, 818)
	$Car2/Sprite.position = Vector2(1200, 818)

	if SONG.player1.contains('pico'):
		THIS.DIE = load('res://game/scenes/game_over-pico.tscn')
	#if !Game.persist.loaded_already:
	#	Game.persist.loaded_already = true
	#	ResourceLoader.load('res://assets/images/characters/pico/ex_death/blood.res')
	#	ResourceLoader.load('res://assets/images/characters/pico/ex_death/smoke.res')

	THIS.cam.position = Vector2(400, 490)

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

func post_ready() -> void:
	#if boyfriend.cur_char.contains('pico'):
	#	boyfriend.cache_char('pico-explode')
	cur_can.atlas = 'res://assets/images/stages/philly-streets/effects/spraycan'
	#cur_can.playing = true
	#$CharGroup.add_child(cur_can)
	cur_can.add_anim_by_frames('kick_up', [0, 7])
	cur_can.add_anim_by_frames('kick_at', [8, 18])
	cur_can.add_anim_by_frames('bonk', [19, 24])
	cur_can.add_anim_by_frames('shot', [26, 44])
	#cur_can.animation_changed.connect(func():
	#	if cur_can.animation == 'hit':
	#		cur_can.offset = Vector2(-450, -70)
	#	else:
	#		cur_can.offset = Vector2(0, 0)
	#)
	#cur_can.sprite_frames = CAN
	#cur_can.position = $SprayCanPile.position + Vector2(650, -170)
	#cur_can.animation_finished.connect(func(): cur_can.visible = cur_can.animation != 'fly')
	#cur_can.visible = false
	THIS.cam.position_smoothing_enabled = true

	if Game.scene.story_mode:
		if Util.format_str(SONG.song) == 'darnell':
			var BITCH = ColorRect.new()
			BITCH.color = Color.BLACK
			BITCH.size = Vector2(1400, 800)
			UI.add_behind(BITCH)

			UI.toggle_objects(false)
			UI.pause_countdown = true
			THIS.speaker.active = false
			THIS.can_pause = false
			THIS.lerp_zoom = false

			var cutscene := Cutscene.new()
			cutscene.play_video('darnellCutscene', true, false, UI.back)

			cutscene.video_finished.connect(func():
				var fucky = func(): dad.dance()
				var fucke = func(): gf.dance(); THIS.speaker.bump()
				dad.animation_finished.connect(fucky)
				gf.animation_finished.connect(fucke)
				dad.dance()
				gf.dance()

				create_tween().tween_property(BITCH, 'modulate:a', 0, 1.5).set_delay(0.3).finished.connect(BITCH.queue_free)

				THIS.cam.position_smoothing_enabled = false
				THIS.move_cam(true)
				THIS.cam.position.x += 250
				THIS.cam.zoom = Vector2(1.3, 1.3)

				boyfriend.play_anim('intro')
				THIS.speaker.look(true)

				cutscene.add_timed_event(0.7, func():
					Audio.play_music('darnellCanCutscene', false)
					cutscene.add_timed_event(Audio.Player.stream.get_length(), func():
						UI.toggle_objects()
						create_tween().tween_property(THIS.cam, 'zoom', Vector2(0.77, 0.77), 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)\
						 .finished.connect(func(): THIS.lerp_zoom = true)
						UI.start_countdown(true)
						THIS.can_pause = true
						THIS.cam.position_smoothing_enabled = true
						THIS.move_cam(false)
						THIS.speaker.active = true

						dad.animation_finished.disconnect(fucky)
						gf.animation_finished.disconnect(fucke)
					)
				)
				var init_delay = 2.0
				cutscene.add_timed_event(init_delay, func():
					THIS.speaker.look(false)
					#THIS.move_cam(false)

					var new_cam_pos:Vector2 = (dad.get_cam_pos() + dad_cam_offset) + Vector2(100, 0)
					#THIS.cam.position.x += 100
					var fuck = create_tween()
					fuck.tween_property(THIS.cam, 'zoom', Vector2(0.66, 0.66), 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
					fuck.parallel().tween_property(THIS.cam, 'position', new_cam_pos, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
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
					THIS.speaker.look(true)
					boyfriend.play_anim('cock')
					Audio.play_sound('weekend/gun_prep')
					create_tween().tween_property(THIS.cam, 'position:x', THIS.cam.position.x + 180, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

					#FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 180 - FlxG.width/2}, 0.4, {ease: FlxEase.backOut});
				)
				#cutscene.add_timed_event(init_delay + 4.166, create_casing)
				cutscene.add_timed_event(init_delay + 4.5, func():
					dad.play_anim('kick')
					Audio.play_sound('weekend/kickUp')
					cur_can.visible = true
					cur_can.play_anim('kick_up')
				)
				cutscene.add_timed_event(init_delay + 4.8, func():
					dad.play_anim('knee')
					dad.can_dance = true
					Audio.play_sound('weekend/kickForward')
					cur_can.play_anim('kick_at')
				)
				cutscene.add_timed_event(init_delay + 5.1, func():
					boyfriend.play_anim('intro-return')
					create_tween().tween_property(THIS.cam, 'position:x', THIS.cam.position.x - 100, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
					#FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 100 - FlxG.width/2}, 2.5, {ease: FlxEase.quadInOut});
					Audio.play_sound('weekend/shots/'+ str(randi_range(1, 4)))
					cur_can.play_anim('shot')

	#				spraycan.playCanShot();
	#				new FlxTimer().start(1/24, function(_)
	#				{
	#					darkenStageProps();
	#				});
				)
				cutscene.add_timed_event(init_delay + 5.9, func():
					THIS.speaker.look(false)
					get_tree().create_timer(0.1, false).timeout.connect(func(): dad.play_anim('laugh'))
					Audio.play_sound('weekend/cutscene/darnell_laugh')
				)
				cutscene.add_timed_event(init_delay + 6.2, func():
					gf.play_anim('laugh')
					Audio.play_sound('weekend/cutscene/nene_laugh')
				)
			)

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
			if Util.rand_bool(90) and boyfriend.cur_char == 'pico':
				boyfriend.play_anim('intro')
				boyfriend.frame = 34
				boyfriend.pause()

				cur_can.play_anim('bonk')
				Audio.play_sound('weekend/bonk')
			else:
				boyfriend.play_anim('shoot' if boyfriend.cur_char == 'pico' else 'attack', true)
				boyfriend.special_anim = true

				Audio.play_sound('weekend/shots/'+ str(randi_range(1, 4)))
				cur_can.play_anim('shot')

var died_by_can:bool = false
func note_miss(note:Note):
	if !note.type.begins_with('weekend-1'): return
	note.no_anim = true
	if note.type.replace('weekend-1-', '') == 'firegun':
		Audio.play_sound('weekend/bonk')
		cur_can.play_anim('bonk')
		boyfriend.play_anim('shootMISS', true)
		boyfriend.special_anim = true
		await get_tree().create_timer(0.3).timeout
		UI.hp = 0
		died_by_can = true

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
			cur_can.visible = true
			cur_can.play_anim('kick_up')
			Audio.play_sound('weekend/kickUp')
		&'kneecan' :
			dad.play_anim('knee', true)
			dad.special_anim = true
			cur_can.play_anim('kick_at')
			Audio.play_sound('weekend/kickForward')

func game_over_start(scene):
	if died_by_can:
		died_by_can = false
		scene.we_dyin = scene.DEATH_TYPE.EXPLODE

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
