extends Node2D

signal on_game_over(scene) # when you first die, with the deathStart anim and sounds
signal on_game_over_idle(scene) # after the timer is done and the deathLoop starts
signal on_game_over_confirm(is_retry:bool, scene) # once you choose to either leave or retry the song

var dead:Character
var this = Game.scene
var last_cam_pos:Vector2
var last_zoom:Vector2
var death_delay:float = 0

var on_death_start:Callable = func(): # once the death sound and deathStart finish playing
	if !retried:
		Audio.play_music('skins/'+ this.cur_skin +'/gameOver')
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
	this.ui.visible = true
	get_tree().paused = false
	this.refresh()
	queue_free()
	this.boyfriend.dance()
	this.gf.play_anim('cheer', true)

var death_sound:AudioStreamPlayer
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
	$Fade.modulate.a = 0
	
	var da_boy = this.boyfriend.death_char
	if da_boy == 'bf-dead' and ResourceLoader.exists('res://assets/data/characters/'+ this.boyfriend.cur_char +'-dead.json'):
		da_boy = this.boyfriend.cur_char +'-dead'
		
	dead = Character.new(this.boyfriend.position, da_boy, true)
	
	dead.play_anim('deathStart', true) # apply the offsets
	#dead.stop()
	add_child(dead)
	move_child(dead, 1)
	
	death_sound = Audio.return_sound('fnf_loss_sfx', true)
	death_sound.play()

	last_cam_pos = this.cam.position
	last_zoom = this.cam.zoom

	create_tween().tween_property($BG, 'modulate:a', 0.7, 0.7).set_trans(Tween.TRANS_SINE)
	timer.start(2.5)
	timer.timeout.connect(on_death_start)
	
	await get_tree().create_timer(0.05).timeout
	dead.play_anim('deathStart', true)

var retried:bool = false
var focused:bool = false
func _process(delta):
	$BG.scale = (Vector2.ONE / this.cam.zoom) + Vector2(0.05, 0.05)
	$BG.position = (get_viewport().get_camera_2d().get_screen_center_position() - (get_viewport_rect().size / 2.0) / this.cam.zoom)
	$BG.position -= Vector2(5, 5) # you could see the stage bg leak out
	$Fade.position = $BG.position
	
	if (dead.frame >= 14 or dead.anim_finished) and !focused:
		focused = true
		this.cam.position_smoothing_speed = 2
		this.cam.position = dead.position + Vector2(dead.width / 2, (dead.height / 2) - 30)

	if !retried:
		this.cam.zoom.x = lerpf(this.cam.zoom.x, 1.05, delta * 4)
		this.cam.zoom.y = this.cam.zoom.x
		
		if Input.is_action_just_pressed('accept'):
			on_game_over_confirm.emit(true, self)
			
			if death_sound != null and death_sound.get_playback_position() < 1.0: # skip to mic drop
				death_sound.play(1)
			timer.paused = false
			timer.start(2)
			timer.timeout.disconnect(on_death_start)
			timer.timeout.connect(on_death_confirm)

			retried = true
			Audio.play_music('skins/'+ this.cur_skin +'/gameOverEnd', false)
			dead.play_anim('deathConfirm', true)
		
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
	if death_sound != null:
		death_sound.stream_paused = !is_focused
