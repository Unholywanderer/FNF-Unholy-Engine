extends AnimatedSprite2D

var strum:Strum
var player:bool = false
const off = {
	'hold' : Vector2(-12, 45),
	'vis'  : Vector2.ZERO
}
var anim_time:float = 0.0 # how long the thing will last

func _ready():
	if get_parent() is Strum:
		strum = get_parent()
		scale = Vector2.ONE

	var to_get:String = 'vis' if Prefs.splash_sprite == 'vis' else 'hold'
	offset = off.get(to_get, Vector2(0, 0))
	sprite_frames = load('res://assets/images/ui/notesplashes/'+ to_get +'_cover.res')
	if sprite_frames.has_animation(Note.COLORS[strum.dir] +'_start'):
		play(Note.COLORS[strum.dir] +'_start')
	else:
		play('start')
	position = strum.position

func _process(delta:float) -> void:
	if strum:
		position = strum.position
		rotation = deg_to_rad(fmod(strum.scroll - 90.0, 180)) + strum.rotation

	if animation == Note.COLORS[strum.dir]:
		anim_time -= delta
		if anim_time <= 0:
			if !player or Prefs.hold_splash == 'cover': return queue_free()
			#if Prefs.hitsound_volume > 0: Audio.play_sound('hitsounds/tail') # maybe make a seperate pref
			play(Note.COLORS[strum.dir] +'_splash')

func _on_animation_finished():
	if animation.ends_with('start'): play(Note.COLORS[strum.dir])
	if animation.ends_with('splash'): queue_free()
