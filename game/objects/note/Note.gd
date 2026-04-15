class_name Note; extends Node2D;

const COLORS:PackedStringArray = ['purple', 'blue', 'green', 'red']
const default_path:String = 'assets/images/ui/skins/%s/notes/'
static var quant_colors:Dictionary[int, Array] = {
	4  : [Color('ff0000'), Color.WHITE, Color('7f0000')],
	8  : [Color('0000ff'), Color.WHITE, Color("000080")],
	12 : [Color("800080"), Color.WHITE, Color("400040")],
	16 : [Color('00ff00'), Color.WHITE, Color("008000")],
	20 : [Color("e60062"), Color.WHITE, Color("a90046")],
	24 : [Color("ffbfc9"), Color.WHITE, Color("805e80")],
	32 : [Color('ffff00'), Color.WHITE, Color("808000")],
	48 : [Color('00ffff'), Color.WHITE, Color("008080")],
	64 : [Color("00c400"), Color.WHITE, Color("006100")],
	192: [Color("bc7cf3"), Color.WHITE, Color("8959b3")],
}

var skin:SkinInfo = (Game.persist.note_skin if Game.persist.note_skin else SkinInfo.new())
var tex_path:String = default_path
var antialiasing:bool = true:
	get: return texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR
	set(alias): texture_filter = Util.get_alias(alias)

var width:float = 0.0:
	get: return (sustain if is_sustain else note).texture.get_width() * abs(scale.x)
var height:float = 0.0:
	get: return (sustain if is_sustain else note).texture.get_height() * abs(scale.y)

var spawned:bool = false
var strum_time:float:
	get: return raw_time + Prefs.offset

var raw_time:float
var dir:int = 0

var early_mod:float = 0.8
var late_mod:float = 1.0
var must_press:bool = false
var speed:float = 1.0:
	set(new_speed):
		speed = new_speed
		if is_sustain: resize_hold()
var velocity:float = 1.0

var alt:String = ""
var gf:bool = false
var no_anim:bool = false
var unknown:bool = false
var type:String = "":
	set(new_type):
		if (new_type.is_empty() or new_type[0] == '0' or new_type == '<null>'\
		 or new_type == 'normal') and type.is_empty(): return

		type = convert_type(new_type)
		if type.begins_with('weekend-1'): return
		match type:
			'Hey': pass
			'Alt': alt = '-alt'
			'Censor': alt = '-censor'
			'No Anim': no_anim = true
			'GF': gf = true
			'Hurt':
				should_hit = false
				early_mod = 0.3
				late_mod = 0.3
				if is_sustain:
					modulate = Color.BLACK
				else:
					tex_path = default_path + 'hurt/note'
			'ugh', 'hehPrettyGood': pass
			_:
				unknown = true

var should_hit:bool = true
var can_hit:bool:
	get:
		if !must_press: return false
		if is_sustain: return strum_time <= Conductor.song_pos and !dropped and parent == null
		return (strum_time > Conductor.song_pos - (Prefs.safe_zone * late_mod) and \
		 strum_time < Conductor.song_pos + (Prefs.safe_zone * early_mod))

var rating:String = ''
var was_good_hit:bool = false:
	get:
		if !must_press: return strum_time <= Conductor.song_pos
		if is_sustain: return roundi(visual_len) <= min_len
		return false

var too_late:bool = false:
	get: return strum_time < Conductor.song_pos - Prefs.safe_zone and !was_good_hit

var parent:Note = null
var is_sustain:bool = false
var length:float = 0.0
var visual_len:float = 0.0

static var min_len:float = 25.0 # before a sustain is counted as "hit"
var holding:bool = false
var drop_time:float = 0.0
var dropped:bool = false:
	set(drop):
		dropped = drop
		if dropped:
			modulate = Color.DIM_GRAY
			alpha = 0.6

var note:Node2D
var sustain:TextureRect
var end:TextureRect
var hold_group:Control
var shader:ShaderMaterial:
	get: return hold_group.material if is_sustain else note.material

var alpha:float = 1.0:
	get: return modulate.a
	set(alpha): modulate.a = alpha

func _init(data = null, sustain_note:bool = false) -> void:
	if data == null: data = NoteData.new()
	is_sustain = (sustain_note and data is Note)
	copy_from(data)
	if is_sustain:
		visual_len = length

var _quant:ShaderMaterial
func _ready() -> void:
	spawned = true
	var can_quant:bool = Prefs.quants and tex_path == default_path
	if can_quant: tex_path += '/quant/'
	tex_path = tex_path % [skin.cur_skin]
	antialiasing = skin.antialiased
	position = Vector2(INF, -INF) #you can see it spawn in for a frame or two
	scale = skin.note_scale

	if is_sustain:
		alpha = 0.6
		# stole from fnf raven because i didnt know how "Control"s worked
		hold_group = Control.new()
		hold_group.clip_contents = true

		add_child(hold_group)
		move_child(hold_group, 0)
		var hold_path:String = tex_path + COLORS[dir] +'_'
		if ResourceLoader.exists(tex_path +'hold.png'): # only a 'hold.png' instead of 4
			hold_path = tex_path

		end = TextureRect.new()
		end.texture = load(hold_path +'end.png')
		end.stretch_mode = TextureRect.STRETCH_TILE
		end.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		end.grow_horizontal = Control.GROW_DIRECTION_BOTH
		end.grow_vertical = Control.GROW_DIRECTION_BEGIN
		end.use_parent_material = true

		sustain = TextureRect.new()
		sustain.texture = load(hold_path +'hold.png')
		sustain.stretch_mode = TextureRect.STRETCH_TILE
		sustain.set_anchors_preset(Control.PRESET_FULL_RECT)
		sustain.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -end.texture.get_height() + 1.0)
		sustain.grow_horizontal = Control.GROW_DIRECTION_BOTH
		sustain.grow_vertical = Control.GROW_DIRECTION_BEGIN
		sustain.use_parent_material = true

		hold_group.add_child(sustain)
		hold_group.add_child(end)

		resize_hold(true)
		if Prefs.behind_strums: hold_group.z_index = -1
	else:
		if ResourceLoader.exists(tex_path +'.res'):
			note = AnimatedSprite2D.new()
			note.sprite_frames = ResourceLoader.load(tex_path +'.res') #skin.cached_note_types['hurt']
			if note.sprite_frames.has_animation(COLORS[dir]):
				note.animation = COLORS[dir]
			note.play(note.animation)
		else:
			note = Sprite2D.new()
			var spr_path:String = tex_path + COLORS[dir] +'.png'
			if ResourceLoader.exists(tex_path +'note.png'): # if theres only a 'note.png' instead of 4 colors
				spr_path = tex_path +'note.png'
			note.texture = load(spr_path)

		add_child(note)

		if unknown:
			modulate = Color.GRAY
			var lol = Sprite2D.new()
			lol.texture = load("res://assets/images/ui/question.png")
			var diff:Vector2 = Vector2(0.7, 0.7)
			if Util.round_d(scale.x, 1) > 0.7:
				diff = lol.scale / scale
			lol.scale = diff
			add_child(lol)
			lol.z_index = 3

	if can_quant:
		_quant = ShaderMaterial.new()
		_quant.shader = Game.persist.cached.get('rgb_shader')
		var colors:Array = Util.get_quant_color(Conductor.get_beat_at(strum_time))
		_quant.set_shader_parameter('red', colors[0])
		_quant.set_shader_parameter('green', colors[1])
		_quant.set_shader_parameter('blue', colors[2])
		_quant.set_shader_parameter('mult', 1.0)
		if !is_sustain:
			note.rotation_degrees = [0, -90, 90, 180][dir]
			note.material = _quant
		else:
			hold_group.material = _quant

func _process(delta:float) -> void:
	if is_sustain and strum_time <= Conductor.song_pos:
		#can_hit = true #!dropped
		#if dropped: return
		#print(visual_len)
		if !holding: drop_time += delta

		if (holding or !must_press): #end piece kinda fucks off a bit every now and then
			drop_time = 0
			holding = true
			visual_len = max((strum_time + length) - Conductor.song_pos, 0)
			#length = visual_len
			resize_hold()

		#was_good_hit = roundi(length) <= min_len

func follow_song_pos(strum:Strum) -> void:
	var pos:float = -(0.45 * ((Conductor.song_pos - strum_time) * velocity) * speed)

	position.x = strum.position.x + (pos * cos(strum.scroll * PI / 180))
	position.y = strum.position.y + (pos * sin(strum.scroll * PI / 180))
	rotation = (deg_to_rad(strum.scroll - 90.0) if sustain else 0.0) + strum.rotation
	if is_sustain and holding:
		position = strum.position
		#raw_time = Conductor.song_pos

func load_skin(_new_skin:String) -> void:
	#skin.load_skin(new_skin)  # this is actually terrible

	tex_path = 'assets/images/ui/skins/%s/notes/' % [skin.cur_skin]

	antialiasing = skin.antialiased
	scale = skin.note_scale

	if is_sustain:
		#scale.y = 0.7
		sustain.texture = load('res://'+ tex_path + COLORS[dir] +'_hold.png')
		end.texture = load(tex_path + COLORS[dir] +'_end.png')
		resize_hold(true)
	else:
		note.texture = load(tex_path + COLORS[dir] +'.png')

func resize_hold(update_control:bool = false) -> void:
	if !spawned: return
	hold_group.size.y = ((visual_len * 0.63) * speed)
	var rounded_scale:float = Util.round_d(skin.note_scale.y, 1)
	if rounded_scale > 0.7:
		hold_group.size.y /= (rounded_scale + (rounded_scale / 2.0))

	if update_control:
		sustain.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -end.texture.get_height() + 1.0)
		hold_group.size.x = maxf(end.texture.get_width(), sustain.texture.get_width())
		hold_group.position.x = (width / 2.0) - (hold_group.size.x / 1.2)

func copy_from(item) -> void:
	if (item is not Note) and (item is not NoteData): return
	if (item is Note):
		raw_time = item.raw_time
		if is_sustain: parent = item
	else:
		raw_time = item.strum_time

	dir = item.dir
	length = item.length
	must_press = item.must_press
	type = item.type

func convert_type(t:String) -> String:
	match t.to_lower().strip_edges():
		'alt animation', 'true', 'mom': return 'Alt'
		'censor': return 'Censor'
		'no animation': return 'No Anim'
		'gf sing': return 'GF'
		'hurt note', '3.0': return 'Hurt'
		'hey!', 'hey': return 'Hey'
		_: return t

class Event extends Note:
	func _init():
		note = Sprite2D.new()
		note.texture = load('res://assets/images/ui/event.png')
		add_child(note)
