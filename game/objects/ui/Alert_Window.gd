class_name AlertWindow; extends Window

@warning_ignore("unused_signal")
signal on_add
signal on_leave

## Icon the window will have
@export_enum('ERROR', 'WARN', 'CHECK', 'INFO') var ALERT_TYPE:String = 'ERROR'
## Max time the window will stay when made (Resets  [code]life_time[/code]  when changed)
@export var max_time:float = 4.0:
	set(new_max):
		max_time = new_max
		life_time = max_time
## How long the window has left until moving offscreen
var life_time:float = 4.0
## Whether or not the  [code]life_time[/code]  can deplete (Useful for times with multiple alerts)
@export var can_die:bool = true

## The current text the alert displays
var text:String = 'This is an Alert Window':
	set(new):
		$Text.text = '[center]'
		$Text.size.y = 23 # reset the size so it can be re-centered
		text = new
		$Text.text += new
		size.y = 100 * max($Text.get_line_count() / 4.0, 1) # this gets more and more off, but its fine
		position = Vector2(20, ((Game.screen[1] - size.y) - 20))
		$Icon.position = Vector2(50, size.y / 2.0)
		$Text.position = Vector2(70, $Icon.position.y - ($Text.size.y / 2.0))

const ALERT_DATA = {
	'ERROR': ['ERROR!', Color.RED, 'cross'],
	'WARN' : ['OOPS!', Color.YELLOW, 'warn'],
	'CHECK': ['SUCCESS', Color.LIME_GREEN, 'check'],
	'INFO' : ['', Color.WHITE, '']
}

func _ready() -> void:
	mouse_entered.connect(func():
		Game.set_mouse_visibility(true)
		life_time = max_time # if you hover over it, reset the life time
		can_die = false
	)
	mouse_exited.connect(func():
		Game.set_mouse_visibility(false)
		can_die = true
	)

	var al = ALERT_DATA[ALERT_TYPE]
	title = al[0]
	add_theme_color_override('title_color', al[1])
	if !al[2].is_empty():
		$Icon.texture = load('res://assets/images/ui/noti_%s.png' % al[2])

	popup()

var id:int = 0
var leaving:bool = false
func _process(delta:float) -> void:
	position = Vector2(20, ((Game.screen[1] - (size.y * id)) - 20)) # i dont want you to drag it FUCK YOU

	if can_die: life_time -= delta
	$LifeBar.value = (life_time / max_time) * 100
	$LifeBar.position.y = size.y - 5
	$LifeBar.size.x = size.x

	if life_time <= 0 and can_die:
		if leaving: return
		leaving = true
		var leave_tween = create_tween().tween_property(self, 'position:x', -size.x * 1.15, 0.7)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
		leave_tween.finished.connect(remove)

func remove() -> void:
	on_leave.emit()
	Alert.all_alerts.erase(self.name)
	queue_free()
