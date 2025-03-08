extends AnimatedSprite2D

var strum:Strum
var player:bool
const col = ['purple', 'blue', 'green', 'red']
var anim_time:float = 0.0 # how long the thing will last

func _ready():
	#if !Prefs.hold_splash: return
	scale = Vector2(0.8, 0.8) # 0.95, 0.95
	#modulate.a = 0.8 #0.6
	play('start')
	position = strum.position + Vector2(-8, 35)
	
func _process(delta:float) -> void:
	if animation == col[strum.dir]:
		anim_time -= delta
		if anim_time <= 0:
			if !player or Prefs.hold_splash == 'cover': return queue_free()
			#if Prefs.hitsound_volume > 0: Audio.play_sound('hitsoundTail') # maybe make a seperate pref
			play(col[strum.dir] +'_splash')

func _on_animation_finished():
	if animation == 'start':
		play(col[strum.dir])
	if animation.ends_with('_splash'):
		queue_free()
