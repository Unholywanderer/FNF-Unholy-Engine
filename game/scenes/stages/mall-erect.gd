extends StageBase

var parents:AnimateSymbol
var santa:AnimateSymbol
func post_ready() -> void:
	var new = ShaderMaterial.new()
	new.shader = load('res://game/resources/shaders/adjust_color.gdshader')
	new.set_shader_parameter('hue', 5)
	new.set_shader_parameter('saturation', 20)

	for i in [boyfriend, gf, dad, $Santa]:
		i.material = new

	if SONG.song == 'Eggnog Erect':
		parents = AnimateSymbol.new()
		parents.atlas = 'res://assets/images/stages/mall/erect/parents'
		parents.position = dad.position + Vector2(-120, 403)
		$CharGroup.add_child(parents)
		parents.loop_mode = 'grah'
		parents.material = dad.material

		santa = AnimateSymbol.new()
		santa.atlas = 'res://assets/images/stages/mall/erect/santa'
		santa.position = $Santa.position + Vector2(383, 350)
		add_child(santa)
		santa.z_index = 30
		santa.loop_mode = 'guhh'

		parents.hide()
		santa.hide()

func beat_hit(_beat:int):
	for i in [$UpperBop/Sprite, $BottomBop, $Santa]:
		i.play()
		i.frame = 0

var seen_shit:bool = false
func song_end() -> void:
	if !seen_shit:
		seen_shit = true
		THIS.can_end = false
		var cutscene := Cutscene.new()
		dad.hide()
		$Santa.hide()
		parents.show()
		santa.show()
		UI.toggle_objects(false, true, 1)

		parents.playing = true
		santa.playing = true

		Audio.play_sound('santa_emotion')

		THIS.cam.position_smoothing_enabled = false
		THIS.lerp_zoom = false

		Util.quick_tween(THIS.cam, 'position', santa.position + Vector2(300, 0), 2.8, Tween.TRANS_EXPO, Tween.EASE_OUT)
		Util.quick_tween(THIS.cam, 'zoom', Vector2(0.73, 0.73), 2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)

		cutscene.add_timed_event(2.8, func():
			Util.quick_tween(THIS.cam, 'position', santa.position + Vector2(150, 0), 9, Tween.TRANS_QUART, Tween.EASE_IN_OUT)
			Util.quick_tween(THIS.cam, 'zoom', Vector2(0.79, 0.79), 9, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		)
		cutscene.add_timed_event(11.375, func(): Audio.play_sound('santa_shot'))
		cutscene.add_timed_event(12.83, func():
			Util.quick_tween(THIS.cam, 'position', santa.position + Vector2(160, 80), 5, Tween.TRANS_EXPO, Tween.EASE_OUT)
		)
		cutscene.add_timed_event(16, func():
			THIS.can_end = true
			THIS.song_end()
		)
