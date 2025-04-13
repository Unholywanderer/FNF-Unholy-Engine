extends Node2D

signal on_game_over(s) # when you first die, with the deathStart anim and sounds
signal on_game_over_idle(s) # after the timer is done and the deathLoop starts
signal on_game_over_confirm(is_retry:bool, s) # once you choose to either leave or retry the song

var dead
var this = Game.scene
var last_cam_pos:Vector2
var last_zoom:Vector2
var death_delay:float = 0
enum DEATH_TYPE {
	EXPLODE,
	PUNCH,
	NORMAL
}
var we_dyin:DEATH_TYPE = DEATH_TYPE.NORMAL
var music:String = 'gameOver-pico'
var on_death_start:Callable = func(): # once the death sound and deathStart finish playing
	if !retried:
		Audio.play_music('skins/'+ this.cur_skin +'/'+ music)
		dead.play_anim('deathLoop')
	on_game_over_idle.emit(self)

var on_death_confirm:Callable = func(): # once the player chooses to retry
	var cam_twen = create_tween().tween_property(this.cam, 'position', last_cam_pos, 1).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property($BG, 'modulate:a', 0, 0.7).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(this.cam, 'zoom', last_zoom, 1).set_trans(Tween.TRANS_SINE)

	await cam_twen.finished
	for i in [this.ui, this.cam, this.boyfriend, this.stage]:
		i.process_mode = Node.PROCESS_MODE_INHERIT
	if this.stage.has_node('CharGroup'):
		for i in this.stage.get_node('CharGroup').get_children():
			i.process_mode = Node.PROCESS_MODE_INHERIT
			
	dead.visible = false
	
	this.cam.position_smoothing_speed = 4
	this.gf.danced = true
	this.boyfriend.visible = true
	this.dad.visible = true
	this.ui.visible = true
	get_tree().paused = false
	this.refresh()
	queue_free()
	this.boyfriend.dance()

var death_sound:AudioStreamPlayer
var retry:AnimatedSprite2D = AnimatedSprite2D.new()

var smoke:AnimatedSprite2D
@onready var timer:Timer = $Timer
func _ready():
	Audio.stop_all_sounds()
	Game.focus_change.connect(focus_change)
	Discord.change_presence('Game Over on '+ this.SONG.song.capitalize() +' - '+ JsonHandler.get_diff.to_upper(), 'I\'ll get it next time maybe')
	
	#await RenderingServer.frame_post_draw
	for i in [this.ui, this.cam, this.stage]:
		i.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if this.stage.has_node('CharGroup'):
		for i in this.stage.get_node('CharGroup').get_children():
			i.process_mode = Node.PROCESS_MODE_DISABLED
		
	this.ui.stop_countdown()
	on_game_over.connect(this.stage.game_over_start)
	on_game_over_idle.connect(this.stage.game_over_idle)
	on_game_over_confirm.connect(this.stage.game_over_confirm)
	
	
	on_game_over.emit(self)

	this.ui.visible = false
	this.boyfriend.visible = false # hide his ass!!!
	Conductor.paused = true
	
	$BG.modulate.a = 0
	$BG.scale = (Vector2.ONE / this.cam.zoom) + Vector2(0.05, 0.05)
	$BG.position = (get_viewport().get_camera_2d().get_screen_center_position() - (get_viewport_rect().size / 2.0) / this.cam.zoom)
	$BG.position -= Vector2(5, 5) # you could see the stage bg leak out
	$Fade.modulate.a = 0
	
	var da_boy = this.boyfriend.death_char
	if we_dyin == DEATH_TYPE.EXPLODE: da_boy = 'pico-explode'
	if da_boy == 'bf-dead' and ResourceLoader.exists('res://assets/data/characters/'+ this.boyfriend.cur_char +'-dead.json'):
		da_boy = this.boyfriend.cur_char +'-dead'
	
	#if we_dyin == DEATH_TYPE.EXPLODE:
		#dead = AnimateSymbol.new()
		#dead.position = this.boyfriend.position - Vector2(100, 200)
		#dead.atlas = 'res://assets/images/characters/pico/ex_death/explosion'
		#dead.playing = false
	#else:
	dead = Character.new(this.boyfriend.position, da_boy, true)
	
	dead.play_anim('deathStart', true) # apply the offsets
	#dead.stop()
	add_child(dead)
	move_child(dead, 1)
	
	var sound_suff:String = '-pico'
	
	match we_dyin:
		DEATH_TYPE.EXPLODE:
			death_delay = 2
			sound_suff += '-explode'
			music = 'gameOver-pico-explode'
			Audio.Player.finished.connect(func():
				if Audio.music.ends_with('-explode'):
					Audio.play_music('gameOver-pico')
			)
			
			var other = AnimatedSprite2D.new()
			other.sprite_frames = ResourceLoader.load('res://assets/images/characters/pico/ex_death/smoke.res')
			other.position = dead.position + Vector2(320, 100)
			add_child(other)
			other.play('start')
			
			retry = AnimatedSprite2D.new()
			retry.sprite_frames = ResourceLoader.load('res://assets/images/characters/pico/ex_death/smoke.res')
			retry.position = dead.position + Vector2(320, 100)
			add_child(retry)
			move_child(retry, dead.get_index())
			retry.play('start')
			other.frame_changed.connect(func():
				if other.frame == 35:
					create_tween().tween_property(other, 'modulate:a', 0, 0.5).finished.connect(other.queue_free)
			)
			
			retry.animation_finished.connect(func(): 
				if retry.animation == 'start': retry.play('loop')
				if retry.animation == 'confirm': retry.queue_free()
			)
			
		DEATH_TYPE.PUNCH:
			sound_suff += '-gutpunch'
			death_delay = -1
			retry.sprite_frames = ResourceLoader.load('res://assets/images/characters/pico/ex_death/blood.res')
			retry.position = dead.position - Vector2(100, 90)
			add_child(retry)
			retry.scale = Vector2(1.75, 1.75)
		_:
			death_delay = -0.8
			var al_la_nene = AnimatedSprite2D.new()
			al_la_nene.sprite_frames = ResourceLoader.load('res://assets/images/characters/pico/ex_death/nene_toss.res')
			al_la_nene.position = this.gf.position + Vector2(290, 200)
			add_child(al_la_nene)
			move_child(al_la_nene, dead.get_index())
			al_la_nene.play('toss')
			al_la_nene.animation_finished.connect(al_la_nene.queue_free)
	
			retry.sprite_frames = load('res://assets/images/characters/pico/ex_death/retry.res')
			retry.position = dead.position + Vector2((dead.width / 3.2) + 10, -20)
			retry.visible = false
			add_child(retry)
	
	death_sound = Audio.return_sound('fnf_loss_sfx'+ sound_suff, true)

	last_cam_pos = this.cam.position
	last_zoom = this.cam.zoom

	if we_dyin == DEATH_TYPE.NORMAL:
		$BG.modulate.a = 1
	else:
		create_tween().tween_property($BG, 'modulate:a', 1, 0.7).set_trans(Tween.TRANS_SINE)
	timer.start(2.5 + death_delay)
	timer.timeout.connect(on_death_start)

	await get_tree().create_timer(0.05).timeout
	dead.play_anim('deathStart', true)
	death_sound.play()
	if we_dyin != DEATH_TYPE.NORMAL:
		retry.play('start')

	if this.dad.cur_char == 'pico':
		await get_tree().create_timer(0.4).timeout
		this.dad.visible = false
		var dead2 = Character.new(this.dad.position - Vector2(1100, 0), 'pico-dead')
		add_child(dead2)

		dead2.play_anim('deathStart', true)
		
		Audio.play_sound('fnf_loss_sfx-pico', 1, true)
		await get_tree().create_timer(1).timeout
		dead2.play_anim('deathLoop')
		var other_music:AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(other_music)
		other_music.stream = load('res://assets/music/skins/default/gameOver-pico.ogg')
		other_music.finished.connect(other_music.play)
		other_music.play()

var retried:bool = false
var focused:bool = false
var stop_sync:bool = false
func _process(delta):
	$BG.scale = (Vector2.ONE / this.cam.zoom) + Vector2(0.05, 0.05)
	$BG.position = (get_viewport().get_camera_2d().get_screen_center_position() - (get_viewport_rect().size / 2.0) / this.cam.zoom)
	$BG.position -= Vector2(5, 5) # you could see the stage bg leak out
	$Fade.position = $BG.position
	
	if (dead.frame >= 14 or dead.anim_finished) and !focused:
		focused = true
		this.cam.position_smoothing_speed = 2
		this.cam.position = dead.position
		match we_dyin:
			DEATH_TYPE.EXPLODE: 
				this.cam.position += Vector2(dead.width / 3.5, (dead.height / 2))
			DEATH_TYPE.PUNCH:
				this.cam.position += Vector2(dead.width / 6.0, -(dead.height / 2.5))
			_: this.cam.position += Vector2(dead.width / 3.5, (dead.height / 2) - 150)

	if !retried:
		var zoo = 1.05 if we_dyin == DEATH_TYPE.NORMAL else 0.9
		this.cam.zoom.x = lerpf(this.cam.zoom.x, zoo, delta * 4)
		this.cam.zoom.y = this.cam.zoom.x
		
		if we_dyin == DEATH_TYPE.NORMAL:
			if retry != null and dead.frame >= 35 and !retry.visible:
				retry.visible = true
				retry.play('loop')
				
		if we_dyin == DEATH_TYPE.PUNCH and !stop_sync:
			stop_sync = dead.frame >= retry.sprite_frames.get_frame_count('start')
			
		if Input.is_action_just_pressed('accept'):
			stop_sync = true
			on_game_over_confirm.emit(true, self)
			
			#if death_sound != null and death_sound.get_playback_position() < 1.0: # skip to mic drop
			#	death_sound.play(1)
			timer.paused = false
			timer.start(2)
			timer.timeout.disconnect(on_death_start)
			timer.timeout.connect(on_death_confirm)

			retried = true
			Audio.play_music('skins/'+ this.cur_skin +'/gameOverEnd-pico', false)
			dead.play_anim('deathConfirm', true)
			if retry != null: 
				retry.play('confirm')
				if we_dyin == DEATH_TYPE.NORMAL:
					create_tween().tween_property(retry, "position:y", retry.position.y - 400, 2.0)\
					 .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.5)
					create_tween().tween_property(retry, 'modulate:a', 0, 1.2).set_delay(0.5)
				
			await get_tree().create_timer(0.5).timeout
			dead.play_anim('deathStart', true, true)
			dead.speed_scale = 1.05
		
		if Input.is_action_just_pressed('back'):
			on_game_over_confirm.emit(false, self)

			timer.stop()
			Audio.stop_music()
			Audio.stop_all_sounds()
			Conductor.reset()
			get_tree().paused = false
			Game.switch_scene('menus/freeplay', true)

func focus_change(is_focused):
	timer.paused = !is_focused
	if death_sound != null: death_sound.stream_paused = !is_focused
	var is_retry_fin:bool = true
	if retry != null: is_retry_fin = (retry.frame == retry.sprite_frames.get_frame_count(retry.animation) - 1)
	if !is_focused:
		if !is_retry_fin: retry.pause()
		dead.pause()
	else:
		if !is_retry_fin: retry.play()
		dead.play()
