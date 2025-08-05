class_name Icon; extends Sprite2D;

@export var image:String = 'face'
@export var is_player:bool = false
var is_menu:bool = false
var follow_spr = null
var center_offset:float = 12.0

@export var default_scale:float = 1.0:
	set(new):
		default_scale = new
		scale = Vector2(new, new)
@export var icon_speed:float = 15.0
const MIN_WIDTH:float = 150.0 # if icon width is less or equal, theres no lose anim
var has_lose:bool = false

var antialiasing:bool = true:
	get: return texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR
	set(anti): texture_filter = Util.get_alias(anti)

var width:float:
	get: return texture.get_width() if texture else 0
var height:float:
	get: return texture.get_height() if texture else 0

func change_icon(new_image:String = 'face', player:bool = false, credit:bool = false) -> void:
	if new_image.begins_with('icon-'): new_image = new_image.replace('icon-', '')

	is_player = player
	image = new_image

	var icon_path:String = 'res://assets/images/icons/icon-%s.png'
	if credit: icon_path = icon_path.replace('icons/', 'credits/').replace('icon-', '')
	if !ResourceLoader.exists(icon_path % image):
		icon_path = 'res://assets/images/icons/icon-%s.png'
		image = 'face'
	texture = load(icon_path % image)

	antialiasing = !image.ends_with('-pixel')
	#has_lose = texture.get_width() > MIN_WIDTH
	has_lose = texture.get_width() > MIN_WIDTH
	default_scale = default_scale if !image.ends_with('-pixel') else 5 # shhhh
	if default_scale > 1:
		has_lose = texture.get_width() > MIN_WIDTH / default_scale

	hframes = 2 if has_lose else 1
	flip_h = is_player

func bump(to_scale:float = 1.2) -> void:
	scale = Vector2(default_scale * to_scale, default_scale * to_scale)
	await RenderingServer.frame_post_draw

func _process(delta):
	var scale_ratio:float = icon_speed / Conductor.step_crochet * 100.0
	scale.x = lerpf(default_scale, scale.x, exp(-delta * scale_ratio))
	scale.y = lerpf(default_scale, scale.y, exp(-delta * scale_ratio))
	if follow_spr:
		if follow_spr is HealthBar: # is healthbar or something
			var bar_width:float = follow_spr.width
			var remapped:float = remap(follow_spr.value, 0, 100, 100, 0) * 0.01
			var cen:float = (((bar_width * remapped) - bar_width) + Game.screen[0] / 1.95) + center_offset
			if is_player:
				position.x = cen + (150 * (scale.x / default_scale) - 150) / 2 - 26
			else:
				position.x = cen - (150 * (scale.x / default_scale)) / 2 - 26 * 2

			position.y = -75 + (75 * (scale.y / default_scale)) # goofy..
			rotation = -follow_spr.rotation
			if has_lose:
				if is_player:
					frame = 1 if follow_spr.value <= 20 else 0
				else:
					frame = 1 if follow_spr.value >= 80 else 0
		else:
			position = follow_spr.position
			position.x += follow_spr.width + 80
			position.y += texture.get_height() / 5.0
