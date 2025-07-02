class_name PixelatedIcon; extends Node2D;

var sprite:Node2D # since it can be both a normal and animated sprite
var is_animated:bool = false
var follow_spr = null

var image:String = '':

var width:float:
	get:
		if !sprite: return 0
		return (sprite.sprite_frames.get_frame_texture('idle', 0).get_width() if is_animated else sprite.texture.get_width()) * scale.x
var height:float:
	get:
		if !sprite: return 0
		return (sprite.sprite_frames.get_frame_texture('idle', 0).get_height() if is_animated else sprite.texture.get_height()) * scale.y

func _ready() -> void:
	texture_filter = Util.get_alias(false)
	add_child(sprite)

func change_icon(new_image:String = 'bf') -> void:
	if new_image.is_empty(): return
	if new_image.contains('-'):
		new_image = new_image.split('-', false)[0]
	image = new_image +'pixel'

	var icon_path:String = 'res://assets/images/icons/freeplay/%s'
	if !ResourceLoader.exists(icon_path % (image +'.png')): # if not found, fallback to using bf
		printerr('No freeplay icon found for %s!' % image)
		image = 'bfpixel'

	scale = Vector2(2, 2)
	is_animated = ResourceLoader.exists(icon_path % (image +'.res'))
	if is_animated:
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = load(icon_path % (image +'.res'))
		sprite.animation_finished.connect(func():
			if sprite.animation == 'confirm':
				sprite.play('confirm-hold')
		)
		sprite.play('idle')
	else:
		sprite = Sprite2D.new()
		sprite.texture = load(icon_path % (image +'.png'))
	#sprite.offset += Vector2(width / 2.0, height / 2.0)

func _process(_delta):
	if follow_spr:
		if follow_spr is HealthBar: # is healthbar or something
			var bar_width:float = follow_spr.width
			var remapped:float = remap(follow_spr.value, 0, 100, 100, 0) * 0.01
			var cen:float = (((bar_width * remapped) - bar_width) + Game.screen[0] / 1.95) + 12
			#if is_player:
			position.x = cen + (150 * scale.x - 150) / 2 - 26
			#else:
			#	position.x = cen - (150 * (scale.x / default_scale)) / 2 - 26 * 2

			position.y = -75 + (75 * scale.y) # goofy..
			rotation = -follow_spr.rotation
		else:
			position = follow_spr.position
			position.x += follow_spr.width + 80
			position.y += height / 5.0
