class_name AlertWindow; extends ColorRect

signal on_add
signal on_leave

## Icon the window will have. Can be 'ERROR', 'WARN', 'CHECK', or 'INFO'
@export_enum('ERROR', 'WARN', 'CHECK', 'INFO') var ALERT_TYPE:String = 'ERROR'
## Max time the window will stay when made, when [code]can_die[/code] is enabled.
## (Resets [code]life_time[/code] when changed!)
@export var max_time:float = 4.0:
	set(new_max):
		max_time = new_max
		life_time = max_time

## How long the window has left until moving offscreen. Only used when [code]can_die[/code] is enabled.
var life_time:float = 4.0

## Whether or not the [code]life_time[/code] can deplete. (Useful for times with multiple alerts)
@export var can_die:bool = true

## The current text the alert displays. Is automatically centered.
var text:String = 'This is an Alert Window':
	set(new):
		$Text.text = '[center]'
		$Text.size.y = 23 # reset the size so it can be re-centered
		text = new
		$Text.text += new
		size.y = 100 * max($Text.get_line_count() / 4.0, 1) # this gets more and more off, but its fine
		#position = Vector2(20, ((Game.screen[1] - size.y) - 20))
		$Icon.position = Vector2(50, size.y / 2.0)
		$Text.position = Vector2(70, $Icon.position.y - ($Text.size.y / 2.0))

const ALERT_DATA = {
	'ERROR': ['ERROR!', Color.RED, 'cross'],
	'WARN' : ['OOPS!', Color.YELLOW, 'warn'],
	'CHECK': ['SUCCESS', Color.LIME_GREEN, 'check'],
	'INFO' : ['', Color.WHITE, '']
} # 696969

var _last_vis:bool
func _ready() -> void:
	mouse_entered.connect(func():
		_last_vis = Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
		Game.set_mouse_visibility(true)
		life_time = max_time # if you hovered over it, reset the life time
		can_die = false
	)
	mouse_exited.connect(func():
		Game.set_mouse_visibility(_last_vis)
		can_die = true
	)

	var data:Array = ALERT_DATA[ALERT_TYPE]
	$Outline.color = Color(data[1] / 1.5, 1)

	if !data[2].is_empty():
		$Icon.texture = load('res://assets/images/ui/noti_%s.png' % data[2])

	position = Vector2(-size.x * 1.15, ((Game.screen[1] - (size.y * (id + 1))) - 20))
	Util.quick_tween(self, 'position:x', 20, 0.4, 'expo', 'out')#.finished.connect(remove)

	$LifeBar.position.y = size.y - 5
	$LifeBar.size.x = size.x
	on_add.emit()

var id:int = 0
var leaving:bool = false
var _tween:Tween
func _process(delta:float) -> void:
	if !can_die or leaving: return
	life_time -= delta
	$LifeBar.value = (life_time / max_time) * 100

	if life_time <= 0:
		leaving = true
		_tween = create_tween()
		_tween.tween_property(self, 'position:x', -size.x * 1.15, 0.7)\
		  .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT).finished.connect(remove)

func refresh() -> void:
	life_time = max_time
	Util.quick_tween(self, 'position:x', 20, 0.4, 'expo', 'out')
	if _tween: _tween.kill()
	leaving = false

func remove() -> void:
	on_leave.emit()
	Alert.remove(name)
	queue_free()
