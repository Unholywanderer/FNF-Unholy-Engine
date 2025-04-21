extends StageBase

var flash:ColorRect
func _ready():
	flash = ColorRect.new()
	flash.modulate.a = 0
	add_child(flash)

var lightning_beat:int = 0
var lighting_offset:int = 8
func song_start():
	lightning_beat = 0

func beat_hit(beat):
	if Util.rand_bool(10) and beat > lightning_beat + lighting_offset:
		strike()

func strike():
	lightning_beat = cur_beat
	lighting_offset = randi_range(8, 24)
	#flash.modulate.a = 0.4
	#create_tween().tween_property(flash, 'modulate:a', 0.5, 0.075)
	#create_tween().tween_property(flash, 'modulate:a', 0, 0.25).set_delay(0.15)

	Audio.play_sound('thunder_'+ str(randi_range(1, 2)))
	$BG.play('strike')
	$BG.frame = 0
	boyfriend.play_anim('scared', true)
	gf.play_anim('scared', true)
