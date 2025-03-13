class_name Speaker3D; extends AnimatedSprite3D;

var parent = null
var offsets:Vector3 = Vector3.ZERO
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
		if i is AnimatedSprite3D:
			i.play()
			if forced: i.frame = 0

func _process(delta:float) -> void:
	for i in addons:
		i.position = position #+ offset
