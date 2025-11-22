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

func _process(_delta:float) -> void:
	#if parent != null: position = parent.position + offsets
	for i in addons:
		i.position = position + offset

class Addon extends AnimatedSprite2D:
	func _init(spr:String, offsets:Array = [0, 0]) -> void:
		name = spr
		sprite_frames = load('res://assets/images/characters/speakers/addons/'+ spr +'.res')
		offset = Vector2(offsets[0], offsets[1])
		centered = false
		use_parent_material = true
		show_behind_parent = true
