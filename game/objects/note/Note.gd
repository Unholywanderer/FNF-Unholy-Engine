class_name Note; extends Node2D;

var skin:SkinInfo = (Game.scene.ui.SKIN if Game.scene.has_node('UI') else SkinInfo.new())
var tex_path:String = 'assets/images/ui/skins/%s/notes/'
var antialiasing:bool = true:
	get: return texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR
	set(alias):
		antialiasing = alias
		texture_filter = Util.get_alias(alias)

var width:float = 0.0:
	get:
		if is_sustain:
			return sustain.texture.get_width() * abs(hold_group.scale.x)
		return note.texture.get_width() * abs(scale.x)
var height:float = 0.0:
	get:
		if is_sustain:
			return sustain.texture.get_height() * abs(hold_group.scale.y)
		return note.texture.get_height() * abs(scale.y)
	
const COLORS:PackedStringArray = ['purple', 'blue', 'green', 'red']

var chart_note:bool = false:
	set(c): set_process(!c); chart_note = c;
var spawned:bool = false
var strum_time:float:
	get: return raw_time + Prefs.offset

var raw_time:float
var dir:int = 0

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
		if (new_type.is_empty() or new_type[0] == '0') and type.is_empty(): return
	
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
				early_mod = 0.5
				late_mod = 0.5
				if is_sustain:
					modulate = Color.BLACK
				else:
					tex_path += 'hurt/note'
			_:
				unknown = true
				modulate = Color.GRAY

var should_hit:bool = true
var can_hit:bool:
	get: 
		if !must_press: return false
		if is_sustain: return strum_time <= Conductor.song_pos #and !dropped
		return (strum_time > Conductor.song_pos - (Conductor.safe_zone * late_mod) and \
		 strum_time < Conductor.song_pos + (Conductor.safe_zone * early_mod))

var early_mod:float = 0.8
var late_mod:float = 1.0
var rating:String = ''
var was_good_hit:bool = false:
	get: return not must_press and strum_time <= Conductor.song_pos
var too_late:bool = false:
	get: return strum_time < Conductor.song_pos - Conductor.safe_zone and !was_good_hit

var is_sustain:bool = false
var length:float = 0.0
var temp_len:float = 0.0 #if you dont immediately hold
var offset_y:float = 0.0

var holding:bool = false
var min_len:float = 10.0 # before a sustain is counted as "hit"
var drop_time:float = 0.0
var dropped:bool = false:
	set(drop): 
		dropped = drop
		if dropped: 
			modulate = Color(0.75, 0.75, 0.75, 0.4)

var note
var sustain:TextureRect
var end:TextureRect
var hold_group:Control

var alpha:float = 1.0:
	get: return modulate.a
	set(alpha): modulate.a = alpha

func _init(data = null, sustain_:bool = false, in_chart:bool = false) -> void:
	if data == null: data = NoteData.new()
	is_sustain = (sustain_ and data is Note)
	copy_from(data)
	chart_note = in_chart
	if is_sustain:
		temp_len = length

func _ready() -> void:
	spawned = true
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
		
		end = TextureRect.new()
		end.texture = load(tex_path + COLORS[dir] +'_end.png') 
		end.stretch_mode = TextureRect.STRETCH_TILE
		end.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		end.grow_horizontal = Control.GROW_DIRECTION_BOTH
		end.grow_vertical = Control.GROW_DIRECTION_BEGIN
		
		sustain = TextureRect.new()
		sustain.texture = load(tex_path + COLORS[dir] +'_hold.png')
		sustain.stretch_mode = TextureRect.STRETCH_TILE
		sustain.set_anchors_preset(Control.PRESET_FULL_RECT)
		sustain.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -end.texture.get_height() + 1.0)
		sustain.grow_horizontal = Control.GROW_DIRECTION_BOTH
		sustain.grow_vertical = Control.GROW_DIRECTION_BOTH
		
		hold_group.add_child(sustain)
		hold_group.add_child(end)
		
		if !chart_note:
			resize_hold(true)
			if Prefs.behind_strums: hold_group.z_index = -1
	else:
		if ResourceLoader.exists(tex_path +'.res'):
			note = AnimatedSprite2D.new()
			note.sprite_frames = skin.cached_note_types['hurt'] #ResourceLoader.load(tex_path +'.res')
			note.play(COLORS[dir])
		else:
			note = Sprite2D.new()
			note.texture = load(tex_path + COLORS[dir] +'.png')
			
		add_child(note)
		
		if unknown:
			var lol = Alphabet.new('?')
			var diff:Vector2 = Vector2.ONE
			if Util.round_d(scale.x, 1) > 0.7: 
				diff = lol.scale / scale
				lol.scale = diff
			lol.position.x -= 22 * diff.x
			lol.position.y -= 30 * diff.y
			add_child(lol)
			lol.z_index = 3

func _process(delta:float) -> void:
	if is_sustain and strum_time <= Conductor.song_pos:
		can_hit = true #!dropped
		#if dropped: return
		temp_len -= (1000 * delta) * Conductor.playback_rate
		
		if (holding or !must_press) and length != temp_len: #end piece kinda fucks off a bit every now and then
			holding = true
			length = temp_len
			resize_hold()
			
		was_good_hit = roundi(length) <= min_len

func follow_song_pos(strum:Strum) -> void:
	var pos:float = -(0.45 * ((Conductor.song_pos - strum_time) * velocity) * speed) #/ Conductor.playback_rate# + offset_y

	position.x = strum.position.x + (pos * cos(strum.scroll * PI / 180))
	position.y = strum.position.y + (pos * sin(strum.scroll * PI / 180))
	rotation = (deg_to_rad(strum.scroll - 90.0) if sustain else 0.0) + strum.rotation
	if is_sustain and holding: 
		position = strum.position

func load_skin(new_skin:String) -> void:
	skin.load_skin(new_skin)  # this is actually terrible

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
	hold_group.size.y = ((length * 0.63) * speed)
	var rounded_scale:float = Util.round_d(skin.note_scale.y, 1)
	if rounded_scale > 0.7: 
		hold_group.size.y /= (rounded_scale + (rounded_scale / 2.0))
	
	if update_control:
		sustain.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -end.texture.get_height() + 1.0)
		hold_group.size.x = maxf(end.texture.get_width(), sustain.texture.get_width())
		hold_group.position.x = (width * 0.5) - hold_group.size.x

func copy_from(item) -> void:
	if item != null and (item is Note or item is NoteData):
		if (item is Note): raw_time = item.raw_time
		else: raw_time = item.strum_time
		
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
		'hurt note', '3.0', 'markov note', 'ebola', 'burger note', 'fart note': return 'Hurt'
		'hey!': return 'Hey'
		_: return t

class Event extends Note:
	func _init():
		note = Sprite2D.new()
		note.texture = load('res://assets/images/ui/event.png')
		add_child(note)
