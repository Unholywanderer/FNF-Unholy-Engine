class_name AlertWindow; extends Window

signal on_add
signal on_leave

## Icon the window will have
@export_enum('Error', 'Warn', 'Check') var ALERT_TYPE:String = 'Error'
## How long the window will last before moving offscreen
@export var life_time:float = 4.0
## Whether or not the  [code]life_time[/code]  can deplete (Useful for times with multiple alerts)
@export var can_die:bool = true

var y_offset:int = 2
## The current text the alert displays
var text:String = 'This is an Alert Window':
	set(new):
		$Text.text = '[center]' 
		$Text.size.y = 23 # reset the size so it can be re-centered
		text = new
		$Text.text += new
		size.y = 100 * max($Text.get_line_count() / 4.0, 1) # this gets more and more off, but its fine
		#position = Vector2(20, ((Game.screen[1] - size.y) - 20) * y_offset) 
		$Icon.position = Vector2(50, size.y / 2.0)
		$Text.position = Vector2(100, $Icon.position.y - ($Text.size.y / 2.0))

const ALERT_DATA = {
	'Error': ['ERROR!', Color.RED, 'cross'], 
	'Warn': ['OOPS!', Color.YELLOW, 'warn'], 
	'Check': ['SUCCESS', Color.LIME_GREEN, 'check']
}
func _ready() -> void:
	on_leave.connect(remove)
	mouse_entered.connect(func():
		Game.set_mouse_visibility(true)
		life_time = 4.0 # if you hover over it, reset the life time
	)
	mouse_exited.connect(func(): Game.set_mouse_visibility(false))
	
	text = 'Saved file at:\nassets/images/GAY'
	
	var al = ALERT_DATA[ALERT_TYPE]
	title = al[0]
	add_theme_color_override('title_color', al[1])
	$Icon.texture = load('res://assets/images/ui/noti_%s.png' % al[2])

	popup()
	
var leaving:bool = false
func _process(delta:float) -> void:
	position = Vector2(20, ((Game.screen[1] - size.y) - 20)) # i dont want you to drag it FUCK YOU
	
	if can_die:
		life_time = max(life_time - delta, 0)
	$LifeBar.value = (life_time / 4.0) * 100
	$LifeBar.position.y = size.y - 5
	if life_time <= 0:
		if !leaving and can_die:
			leaving = true
			var outta_here = create_tween()
			outta_here.tween_property(self, 'position:x', -size.x * 1.15, 0.5).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT)
			outta_here.finished.connect(func(): 
				on_leave.emit()
				remove()
			)

func remove() -> void:
	#AlertHandler.alert_count -= 1
	queue_free()

func _on_close_requested() -> void: # no you may not close!!
	pass # Replace with function body.
