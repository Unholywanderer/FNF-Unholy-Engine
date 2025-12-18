extends Control

## When you first die, emitted BEFORE the deathStart anim and sounds
signal on_game_over()
## After the timer is done and the idle deathLoop starts
signal on_game_over_idle()
## Once you choose to either leave or retry the song
signal on_game_over_confirm(is_retry:bool)

# always have these loaded since its the normal game over shit
const nene_frames:SpriteFrames = preload('res://assets/images/characters/pico/ex_death/nene_toss.res')
const retry_frames:SpriteFrames = preload('res://assets/images/characters/pico/ex_death/retry.res')

var pico:Character
var this := Game.scene
var cam:Camera2D = this.cam #get_viewport().get_camera_2d()

enum TYPES {
	## Nene throws knife and pico bleeds to death
	NORMAL,
	## Paint can explodes on pico
	EXPLODE,
	## Pico got his shit rocked
	PUNCH,
	## Love hurts or something like that
	NENE,
}
@export var death_delay:float = 0.0
@export var death_type:TYPES = TYPES.NORMAL
@export var death_char:String = ''
@export var death_music:String = 'gameOver-pico'

var on_death_start:Callable = func(): # once the death sound and deathStart finish playing
	if !retried:
		Audio.play_music('skins/%s/%s' % [this.cur_skin, death_music])
		pico.play_anim('deathLoop')
	on_game_over_idle.emit()
	timer.timeout.disconnect(on_death_start)

var on_death_confirm:Callable = func(): # once the player chooses to retry
	cam.process_mode = Node.PROCESS_MODE_INHERIT

	Util.quick_tween(fade, 'color:a', 1, 0.7, 'sine').set_delay(1.0)
	var zoom := create_tween()
	zoom.tween_method(func(val):
		cam.zoom = val
		follow_bg()
	, cam.zoom, Vector2(0.4, 0.4), 1.6).set_delay(0.2).set_trans(Tween.TRANS_QUAD)

	zoom.finished.connect(func():
		await RenderingServer.frame_post_draw
		Game.reset_scene()
		queue_free()
	)

var _death_audio:AudioStreamPlayer
var retry:AnimatedSprite2D

@onready var timer:Timer = $Timer
@onready var bg:ColorRect = %BG
@onready var fade:ColorRect = %Fade
func _ready():
	Audio.stop_all_sounds()

	Conductor.paused = true

	Game.focus_change.connect(focus_change)
	Discord.change_presence('Game Over | '+ this.SONG.song.capitalize() +' - '+ JsonHandler.get_diff.to_upper(), 'I\'ll get it next time maybe')

	follow_bg()
	cam.process_mode = Node.PROCESS_MODE_ALWAYS

	on_game_over.connect(this.stage.game_over_start)
	on_game_over_idle.connect(this.stage.game_over_idle)
	on_game_over_confirm.connect(this.stage.game_over_confirm)

	on_game_over.emit()

	this.ui.visible = false

	pico = this.boyfriend
	pico.reparent(self)
	pico.material = null

	if death_char.is_empty(): # if empty, get the death char from the json
		death_char = pico.death_char

	if death_type == TYPES.EXPLODE:
		death_char = pico.cur_char +'-explode'

	if !death_char.is_empty():
		pico.global_position = this.stage.bf_pos
		pico.load_char(death_char)
	pico.play_anim('deathStart', true) # apply the offset

	var sound_suff:String = '-pico'

	match death_type:
		TYPES.EXPLODE:
			death_delay = 1.55
			sound_suff += '-explode'
			death_music += '-explode'
			Audio.Player.finished.connect(func():
				if Audio.music.ends_with('-explode'):
					Audio.play_music('skins/'+ this.cur_skin +'/gameOver-pico')
			)
		TYPES.PUNCH:
			sound_suff += '-gutpunch'
			death_delay = -1
		TYPES.NENE:
			sound_suff += '-and-nene'
			death_delay = -1
			cam.position = pico.get_cam_pos()
		_:
			death_delay = -0.8
			var el_nene = AnimatedSprite2D.new()
			el_nene.centered = false
			el_nene.sprite_frames = nene_frames
			el_nene.position = this.gf.global_position + Vector2(150, 0)
			add_child(el_nene)
			move_child(el_nene, pico.get_index())
			el_nene.play('toss')
			el_nene.animation_finished.connect(el_nene.queue_free)

			if !pico.cur_char.ends_with('-pixel-dead'): # pixel pico has his own baked in
				retry = AnimatedSprite2D.new()
				retry.sprite_frames = retry_frames
				retry.position = pico.position + Vector2((pico.width / 3.2) + 10, -20)
				retry.visible = false
				add_child(retry)
				retry.top_level = true

	_death_audio = Audio.return_sound('fnf_loss_sfx'+ sound_suff, true)

	if death_type == TYPES.NORMAL:
		bg.color.a = 1
	else:
		Util.quick_tween(bg, 'color:a', 1, 0.7, 'sine')
	timer.start(2.5 + death_delay)
	timer.timeout.connect(on_death_start)

	_death_audio.play()

var retried:bool = false
var focused:bool = false
var stop_sync:bool = false
func _process(delta):
	follow_bg()

	if (((pico.is_atlas and pico.atlas.frame_index >= 14) or pico.frame >= 14) or
	   pico.anim_finished) and !focused:
		focused = true
		cam.position_smoothing_speed = 2
		cam.position = pico.get_cam_pos()
		#match death_type:
		#	TYPES.EXPLODE:
		#		cam.position += Vector2(pico.width / 3.5, (pico.height / 2))
		#	TYPES.PUNCH:
		#		cam.position += Vector2(pico.width / 6.0, -(pico.height / 2.5))
		#	_: cam.position += Vector2(pico.width / 3.5, (pico.height / 2) - 150)

	if !retried:
		var zoo:float = 1.05 if death_type == TYPES.NORMAL else 0.9
		cam.zoom.x = lerpf(cam.zoom.x, zoo, delta * 4)
		cam.zoom.y = cam.zoom.x

		if death_type == TYPES.NORMAL and retry and pico.frame >= 35 and !retry.visible:
			retry.visible = true
			retry.play('loop')

		if Input.is_action_just_pressed('accept'):
			stop_sync = true
			on_game_over_confirm.emit(true)

			timer.paused = false
			timer.start(2)
			timer.timeout.connect(on_death_confirm)

			retried = true
			Audio.play_music('skins/'+ this.cur_skin +'/gameOverEnd-pico', false)
			if pico.has_anim('deathConfirm'):
				pico.play_anim('deathConfirm', true)
			if retry:
				retry.play('confirm')
				if death_type == TYPES.NORMAL:
					Util.quick_tween(retry, "position:y", retry.position.y - 400, 2.0, 'cubic', 'in')\
					.set_delay(0.5)
					Util.quick_tween(retry, 'modulate:a', 0, 1.2).set_delay(0.5)

		if Input.is_action_just_pressed('back'):
			on_game_over_confirm.emit(false)

			timer.stop()
			Audio.stop_music()
			Audio.stop_all_sounds()
			Conductor.reset()
			get_tree().paused = false
			Game.switch_scene('menus/freeplay_classic', true)

func add_over(obj:Variant) -> void:
	$Overlay.add_child(obj)

func follow_bg() -> void:
	bg.scale = (Vector2.ONE / cam.zoom) + Vector2(0.05, 0.05)
	bg.position = (get_viewport().get_camera_2d().get_screen_center_position() - (get_viewport_rect().size / 2.0) / cam.zoom)
	bg.position -= Vector2(5, 5) # you could see the stage bg leak out
	fade.position = bg.position
	fade.scale = bg.scale

func focus_change(is_focused):
	timer.paused = !is_focused
	if _death_audio: _death_audio.stream_paused = !is_focused
	var is_retry_fin:bool = true
	if retry and retry.sprite_frames:
		is_retry_fin = (retry.frame == retry.sprite_frames.get_frame_count(retry.animation) - 1)
	if !is_focused:
		if !is_retry_fin: retry.pause()
		if !pico.is_atlas: pico.pause()
	else:
		if !is_retry_fin: retry.play()
		if !pico.is_atlas: pico.play()
