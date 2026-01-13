class_name HealthBar; extends Control;

@onready var bar = $Bar
@onready var spr = $Sprite

var width:float:
	get: return $Bar.get_size()[0]

var height:float:
	get: return $Bar.get_size()[1]

@export var value:float = 50.0:
	set(new_val):
		value = new_val
		$Bar.value = value

var fill_mode:int = 1:
	set(new_fill):
		fill_mode = clampi(new_fill, 0, 3)
		$Bar.fill_mode = fill_mode

@export var left_color:Color = Color.RED:
	set(new):
		left_color = new
		$Bar.get_theme_stylebox("background").bg_color = new

@export var right_color:Color = Color(0.4, 1, 0.2):
	set(new):
		right_color = new
		$Bar.get_theme_stylebox("fill").bg_color = new

var style_box:Dictionary = {'background': null, 'fill': null}
func set_colors(left:Color, right:Color) -> void: # i might use this maybe who knows
	if left != null: $Bar.get_theme_stylebox("background").bg_color = left
	if right != null: $Bar.get_theme_stylebox("fill").bg_color = right

func _ready():
	if $Sprite == null:
		var new = Sprite2D.new()
		new.name = 'Sprite'
		#new.texture = load('res://assets/images/ui/healthBar.png')
		add_child(new)
	if $Bar == null:
		var new = ProgressBar.new()
		new.name = 'Bar'
		add_child(new)

	style_box.background = $Bar.get_theme_stylebox('background').duplicate()
	style_box.fill = $Bar.get_theme_stylebox('fill').duplicate()
