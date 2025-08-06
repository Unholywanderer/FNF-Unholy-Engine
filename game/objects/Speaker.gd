class_name Speaker; extends AnimatedSprite2D;

var parent = null
var offsets:Vector2 = Vector2.ZERO
var addons:Array = []
func _init(par = null) -> void:
	centered = false
	name = 'Speaker'
	sprite_frames = load('res://assets/images/characters/speakers/speaker.res')
	if par != null:
		parent = par

func bump(forced:bool = true) -> void:
	play('bump')
	if forced: frame = 0
	for i in addons:
		if i is AnimatedSprite2D:
			i.play()
			if forced: i.frame = 0

@warning_ignore("unused_parameter")
func _process(delta:float) -> void:
	#if parent != null: position = parent.position + offsets
	for i in addons:
		i.position = position + offset
