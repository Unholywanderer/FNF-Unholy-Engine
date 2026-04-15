class_name Strum; extends AnimatedSprite2D;

const DIRECTION:PackedStringArray = ['left', 'down', 'up', 'right']

var skin:SkinInfo = SkinInfo.new()
@export var is_event:bool = false:
	set(ev):
		is_event = ev
		if ev: sprite_frames = load('res://assets/images/ui/eventStrum.res')
		else: load_skin(skin.cur_skin)

@export var is_player:bool = false
@export var dir:int = 0:
	set(new_dir):
		dir = new_dir
		play_anim(animation.get_slice('_', 1))

@export var scroll:float = 90.0

# not really for downscroll, just flips the scroll direction
@export var downscroll:bool = false:
	set(d):
		if d != downscroll:
			downscroll = d
			scroll *= -1

var width:float:
	get:
		var _anim:String = '' if is_event else DIRECTION[dir] +'_'
		return sprite_frames.get_frame_texture(_anim +'static', 0).get_width() * scale.x
var height:float:
	get:
		var _anim:String = '' if is_event else DIRECTION[dir] +'_'
		return sprite_frames.get_frame_texture(_anim +'static', 0).get_height() * scale.y

var anim_timer:float = 0.0 # used for confirm anim looping on sustains
var reset_timer:float = 0.0 # how long until the animation can return to static
var antialiasing:bool = true:
	get: return texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR
	set(alias): texture_filter = Util.get_alias(alias)

var rgb_enabled:bool = false
var rgb_shader:ShaderMaterial = ShaderMaterial.new()
var rgb_allowed:bool = false:
	set(allow):
		rgb_allowed = allow and rgb_enabled
		material = rgb_shader if rgb_allowed else null

func _ready():
	if !is_event:
		scale = Vector2(0.7, 0.7)
	play_anim('static')

func _process(delta):
	anim_timer = maxf(anim_timer - delta, 0)
	if reset_timer > 0:
		reset_timer -= delta
		if reset_timer <= 0:
			play_anim('static')

func load_skin(new_skin:String = 'default'):
	#var _last = []
	#if !animation.contains('static'):
	#	_last = [animation, frame]
	if Game.persist.note_skin: #and new_skin == Game.persist.note_skin.cur_skin:
		skin = Game.persist.note_skin
	else:
		skin.load_skin(new_skin)

	sprite_frames = skin.strum_skin
	scale = skin.strum_scale
	antialiasing = skin.antialiased
	#if _last.size() > 0:
	#	play_anim(_last[0])
	#	frame = _last[1]
	#else:
	play_anim('static')

func play_anim(anim:String, forced:bool = false):
	rgb_allowed = !anim.contains('static')
	if rgb_allowed and anim == 'press':
		rgb_shader.set_shader_parameter('red', Color.DIM_GRAY)
		rgb_shader.set_shader_parameter('green', Color.WHITE)
		rgb_shader.set_shader_parameter('blue', Color.DARK_GRAY)
	if anim == 'static':
		reset_timer = 0
	if !anim.contains(DIRECTION[dir]) and !is_event:
		anim = DIRECTION[dir] +'_'+ anim

	play(anim)
	if forced: frame = 0

func toggle_rgb(enable:bool = false) -> void:
	rgb_enabled = enable
	rgb_shader.shader = Game.persist.cached.get('rgb_shader') if enable else null
	if enable: rgb_shader.set_shader_parameter('mult', 1.0)
	sprite_frames = skin.strum_skin_rgb if enable else skin.strum_skin

func copy_rgb(mat:Material) -> void:
	if !rgb_allowed or !rgb_shader or !mat: return
	material.set_shader_parameter('red', mat.get_shader_parameter('red'))
	material.set_shader_parameter('green', mat.get_shader_parameter('green'))
	material.set_shader_parameter('blue', mat.get_shader_parameter('blue'))
	material.set_shader_parameter('mult', 1.0)
