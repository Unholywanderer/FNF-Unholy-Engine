extends AnimatedSprite2D

var strum:Strum
var player:bool = false
const col = ['purple', 'blue', 'green', 'red']
const off = {'normal': Vector2(-12, 45)}
var anim_time:float = 0.0 # how long the thing will last

func _ready():
	if get_parent() is Strum:
		strum = get_parent()
		scale = Vector2.ONE
	#if !Prefs.hold_splash: return
	#scale = Vector2(0.7, 0.7) # 0.95, 0.95
	#modulate.a = 0.8 #0.6
	offset = off.get('', Vector2(0, 0))
	if sprite_frames.has_animation(col[strum.dir] +'_start'):
		play(col[strum.dir] +'_start')
	else:
		play('start')
	position = strum.position

func _process(delta:float) -> void:
	if strum:
		position = strum.position
		rotation = deg_to_rad(fmod(strum.scroll - 90.0, 180)) + strum.rotation

	if animation == col[strum.dir]:
		anim_time -= delta
		if anim_time <= 0:
			if !player or Prefs.hold_splash == 'cover': return queue_free()
			#if Prefs.hitsound_volume > 0: Audio.play_sound('hitsounds/tail') # maybe make a seperate pref
			play(col[strum.dir] +'_splash')

func _on_animation_finished():
	if animation.ends_with('start'):
		play(col[strum.dir])
	if animation.ends_with('splash'):
		queue_free()
