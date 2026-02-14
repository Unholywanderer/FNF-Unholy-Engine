extends Control

## when you first die, with the deathStart anim and sounds
signal on_game_over()
## after the timer is done and the deathLoop starts
signal on_game_over_idle()
## once you choose to either leave or retry the song
signal on_game_over_confirm(is_retry:bool)

var bf:Character
var this := Game.scene
var cam:Camera2D = this.cam #get_viewport().get_camera_2d()

var is_fakeout:bool = false

@export var death_char:String = this.boyfriend.death_char
@export var death_delay:float = 0.0
@export var death_sound:String = 'fnf_loss_sfx'
@export var death_music:String = 'gameOver'
@export var death_end:String = 'gameOverEnd'
@export var bpm:float = 100.0

var on_death_start:Callable = func(): # once the death sound and deathStart finish playing
	if !retried:
		#Conductor.paused = false
		#Conductor.song_started = true
		#Audio.sync_conductor = true
		Audio.play_music('skins/%s/%s' % [this.cur_skin, death_music])
		bf.play_anim('deathLoop')
	on_game_over_idle.emit()
	timer.timeout.disconnect(on_death_start)

var on_death_confirm:Callable = func(): # once the player chooses to retry
	#Audio.sync_conductor = false
	#Conductor.process_mode = Node.PROCESS_MODE_INHERIT
	cam.process_mode = Node.PROCESS_MODE_INHERIT

	Util.quick_tween(fade, 'color:a', 1, 0.7, 'sine').set_delay(1.0)
	var zoom := create_tween()
	zoom.tween_method(func(val):
		cam.zoom = val
		follow_bg()
	, cam.zoom, Vector2(0.4, 0.4), 1.6).set_delay(0.3).set_trans(Tween.TRANS_QUAD)

	zoom.finished.connect(func():
		await RenderingServer.frame_post_draw
		Game.reset_scene()
		queue_free()
	)

var _death_audio:AudioStreamPlayer
@onready var timer:Timer = $Timer
@onready var bg:ColorRect = %BG
@onready var fade:ColorRect = %Fade

func _ready():
	Audio.stop_all_sounds()

	#Conductor.process_mode = Node.PROCESS_MODE_ALWAYS
	#Conductor.beat_hit.connect(beat_hit)
	#Conductor.reset()
	#Conductor.bpm = bpm
	Conductor.paused = true

	Game.focus_change.connect(focus_change)
	Discord.change_presence('Game Over | '+ this.SONG.song.capitalize() +' - '+ JsonHandler.cur_diff.to_upper(), 'MOTHER FUCK')
	follow_bg()

	on_game_over.connect(this.stage.game_over_start)
	on_game_over_idle.connect(this.stage.game_over_idle)
	on_game_over_confirm.connect(this.stage.game_over_confirm)

	bf = this.boyfriend
	bf.global_position = this.stage.bf_pos
	bf.reparent(self)
	bf.load_char(death_char) #TODO flips very weirdly when player isnt an is_player character
	bf.play_anim('deathStart', true) # apply the offsets

	cam.process_mode = Node.PROCESS_MODE_ALWAYS

	on_game_over.emit()

	this.ui.visible = false

	_death_audio = Audio.return_sound(death_sound, true)
	_death_audio.play()

	create_tween().tween_property(bg, 'color:a', 1, 0.7).set_trans(Tween.TRANS_SINE)
	timer.start(2.5)
	timer.timeout.connect(on_death_start)

var retried:bool = false
var focused:bool = false
func _process(delta):
	follow_bg()

	if (bf.frame >= 14 or bf.anim_finished) and !focused:
		focused = true
		cam.position_smoothing_speed = 2
		cam.position = bf.get_cam_pos()

	if !retried:
		cam.zoom.x = lerpf(cam.zoom.x, 1.05, delta * 4)
		cam.zoom.y = cam.zoom.x

		if Input.is_action_just_pressed('accept'):
			on_game_over_confirm.emit(true)

			timer.paused = false
			timer.start(2)
			timer.timeout.connect(on_death_confirm)

			retried = true
			Audio.play_music('skins/'+ this.cur_skin +'/gameOverEnd', false)
			bf.play_anim('deathConfirm', true)

		if Input.is_action_just_pressed('back'):
			on_game_over_confirm.emit(false)

			timer.stop()
			Audio.stop_music()
			Audio.stop_all_sounds()
			#Conductor.process_mode = Node.PROCESS_MODE_INHERIT
			Conductor.reset()
			get_tree().paused = false
			Game.switch_scene('menus/freeplay_classic', true)

func beat_hit(beat:int) -> void:
	if bf.has_anim('deathDanceLeft') and bf.has_anim('deathDanceRight'):
		bf.play_anim('deathDance'+ ('Left' if beat % 2 == 0 else 'Right'))
	if bf.has_anim('deathIdle') and beat % 2 == 0:
		bf.play_anim('deathIdle', true)

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
	if !is_focused:
		#Conductor.process_mode = Node.PROCESS_MODE_DISABLED
		bf.pause()
	else:
		#Conductor.process_mode = Node.PROCESS_MODE_ALWAYS
		bf.play()
