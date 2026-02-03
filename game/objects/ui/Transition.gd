extends CanvasLayer

signal finished(part:int) # 0 is trans out, 1 is trans in
var tween

var _out:bool = false
var cur_tex:String = ''
var in_progress:bool = false

const TEX_PATH:String = 'assets/images/ui/transitions/%s.png'
const RARE_IMAGES:Array[String] = ['bald', 'bowser', 'boyfriend', 'miku', 'scrunkly', 'natsuki', 'steve']
const HOLE_IMAGES:Array[String] = ['circle', 'icon', 'skry', 'bf', 'dad', 'gf']
@onready var hole = $Group/Hole
@onready var black = $Group/Black
var on_finish:Callable = func():
	#Game.scene.paused = false
	#Game.remove_child(self)
	queue_free()

func trans_in(speed:float = 0.7, call_func:bool = false) -> void:
	hole.scale = Vector2(0, 0)
	_out = false
	start()

	tween.tween_property(hole, 'scale', Vector2(15, 15), speed)
	get_tree().create_timer(speed, false).timeout.connect(func():
		in_progress = false
		finished.emit(1)

		if call_func:
			on_finish.call()
	)

func trans_out(speed:float = 0.7, call_func:bool = false) -> void:
	hole.scale = Vector2(15, 15)
	_out = true
	start()
	if cur_tex == 'bowser': speed = 2

	tween.tween_property(hole, 'scale', Vector2(0, 0), speed)
	await tween.finished
	in_progress = false
	finished.emit(0)

	if call_func:
		on_finish.call()

func start() -> void:
	in_progress = true

	var chance = _out and Util.rand_bool(5)
	var new_tex:String = RARE_IMAGES.pick_random() if chance else HOLE_IMAGES.pick_random()
	cur_tex = new_tex
	if new_tex == 'bowser':
		Audio.play_sound('cackle', 0.7)

	if chance: new_tex = 'rare/'+ new_tex
	hole.texture = load(TEX_PATH % new_tex) # funny random

	if tween: tween.kill()
	tween = create_tween()
	#tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)

	Util.center_obj(hole)
	black.scale = Vector2(1300, 730)
	black.position = Vector2(Game.screen[0] / 2, Game.screen[1] / 2)

func cancel() -> void:
	in_progress = false
	if tween: tween.kill()

	black.scale = Vector2.ZERO
	hole.scale = Vector2.ZERO
	queue_free()
