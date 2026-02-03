class_name Character; extends AnimatedSprite2D;

var json:Dictionary
var atlas:Atlas
var chart:Array = []
var char_cache:Dictionary = {}
var offsets:Dictionary = {}
var flippers:Dictionary = {}
var speaker_data:Dictionary = {}
var focus_offsets:Vector2 = Vector2.ZERO # cam offset type shit

var cur_char:String = ''
var icon:String = 'bf'
var death_char:String = 'bf-dead'

var debug:bool = false
var is_player:bool = false
var is_atlas:bool = false:
	set(atl):
		if atl == is_atlas: return
		if atl:
			atlas = Atlas.new()
			sprite_frames = null
			add_child(atlas)
			atlas.finished.connect(func():
				if debug: return
				var anim := get_anim()
				if has_anim(anim +'-loop') and offsets.has(anim +'-loop'):
					looping = true
					play_anim(anim +'-loop')
			)

		else:
			remove_child(atlas)

		is_atlas = atl

var idle_suffix:String = ''
var forced_suffix:String = '' # if set, every anim will use it
var can_dance:bool = true
var ignore_anims:bool = false
var looping:bool = false

var dance_idle:bool = false
var danced:bool = false
var dance_beat:int = 2 # dance every %dance_beat%

var hold_timer:float = 0.0
var sing_duration:float = 4.0
var sing_timer:float = 0.0 # for anim looping with sustains

var last_anim:StringName = ''
var special_anim:bool = false: set = set_special_anim
func set_special_anim(spec): # like this so i can override it
	if spec: last_anim = atlas.cur_anim if is_atlas else animation
	special_anim = spec

var anim_timer:float = -1.0: # play an anim for a certain amount of time
	set(time):
		anim_timer = time
		if !special_anim and time > 0:
			special_anim = true

var on_anim_finished:Callable = func():
	special_anim = false
	can_dance = true
	ignore_anims = false
	dance()
	if is_atlas:
		atlas.finished.disconnect(on_anim_finished)
	else:
		animation_finished.disconnect(on_anim_finished)

var anim_finished:bool:
	get: return (atlas.frame_index if is_atlas else frame) == get_frame_count(animation) - 1

var width:float:
	get: return width * abs(scale.x)
var height:float:
	get: return height * abs(scale.y)

var antialiasing:bool = true:
	get: return texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
	set(anti): texture_filter = Util.get_alias(anti)

var sing_anims:PackedStringArray = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT']

func _init(pos:Vector2 = Vector2.ZERO, Char:String = 'bf', player:bool = false):
	centered = false
	#atlas = AnimateSymbol.new()
	animation_finished.connect(func():
		if debug: return
		var anim := get_anim()
		if has_anim(anim +'-loop') and offsets.has(anim +'-loop'):
			looping = true
			play_anim(anim +'-loop')
	)

	is_player = player
	position = pos

	load_char(Char)

func _notification(what:int) -> void: # exit_tree is goofy
	if what == NOTIFICATION_PREDELETE and atlas:
		atlas.queue_free() # go my orphan nodes

func load_char(new_char:String = 'bf') -> void:
	if new_char == cur_char or new_char.is_empty():
		return print(new_char +' already loaded')

	cur_char = new_char
	if !ResourceLoader.exists('res://assets/data/characters/%s.json' % cur_char):
		var replace_char = get_closest(cur_char)
		print_rich('No JSON found for: '+ cur_char +'\n', '[color=red]'+ cur_char +'[color=yellow] -> [color=green]'+ replace_char)
		cur_char = replace_char

	json = JsonHandler.get_character(cur_char) # get offsets and anim names...
	if json.has('no_antialiasing'): json = Legacy.fix_json(json)
	if json.has('assetPath'): json = VSlice.fix_json(json)

	var path:String = json.path +'.res'
	is_atlas = ResourceLoader.exists('res://assets/images/'+ path.get_basename() +'/Animation.json')
	if is_atlas:
		path = path.get_basename()
		if !DirAccess.dir_exists_absolute('res://assets/images/'+ path):
			return printerr('No atlas folder found: '+ path)

		atlas.atlas = 'res://assets/images/'+ path
		#add_child(atlas)
	else:
		if !ResourceLoader.exists('res://assets/images/'+ path): # json exists, but theres no res file
			printerr('No .res file found: '+ path)
			path = 'characters/bf/char.res'

		if char_cache.has(cur_char):
			sprite_frames = char_cache[cur_char]
		else:
			sprite_frames = ResourceLoader.load('res://assets/images/'+ path)
			char_cache[cur_char] = sprite_frames.duplicate(true)

	offsets.clear()
	for anim in json.animations:
		add_anim(anim.name, anim.prefix, anim.frames, anim.framerate, anim.loop)
		offsets[anim.name] = anim.offsets
		flippers[anim.name] = anim.get('flip_x', false)

		#if anim.name != anim.prefix and has_anim(anim.prefix) and !to_remove.has(anim.prefix):
		#	to_remove.append(anim.prefix)

	#for i:String in to_remove: sprite_frames.remove_animation(i)

	icon = json.icon
	scale = Vector2(json.scale, json.scale)
	antialiasing = json.antialiasing
	position.x += json.pos_offset[0]
	position.y += json.pos_offset[1]
	focus_offsets.x = json.cam_offset[0]
	focus_offsets.y = json.cam_offset[1]
	death_char = json.get('death_char', 'bf-dead')
	sing_duration = json.get('sing_dur', 4)

	speaker_data.clear()
	if json.has('speaker'):
		speaker_data = json.speaker

	dance_idle = offsets.has('danceLeft') and offsets.has('danceRight')

	match(cur_char):
		'senpai':
			dance_beat = 2
		'senpai-angry':
			forced_suffix = '-alt' # boooo
		'pico-speaker', 'otis-speaker':
			can_dance = false
			if cur_char == 'otis-speaker':
				animation_changed.connect(func(): can_dance = animation == 'idle')
				animation_finished.connect(func(): if animation != 'idle': play_anim('idle'))
				can_dance = true
			sing_anims = ['shootLeft', 'shootLeft', 'shootRight', 'shootRight']
			play_anim('idle', true)
		_:
			dance_beat = 1 if dance_idle else 2
			sing_anims = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT']

	dance()
	set_stuff()
	if is_player != json.facing_left:
		flip_char()

	print('loaded '+ cur_char)

func _process(delta):
	if debug: return
	if special_anim:
		if anim_timer < 0:
			var le_signal:Signal = atlas.finished if is_atlas else animation_finished
			if !le_signal.is_connected(on_anim_finished):
				le_signal.connect(on_anim_finished)
		else:
			anim_timer = max(anim_timer - delta, 0)
			if anim_timer <= 0.0:
				special_anim = false
				if get_anim() == last_anim:
					dance()
	else:
		if animation.begins_with('sing'):
			hold_timer += delta
			sing_timer += delta

			var holding = Input.is_action_pressed('note_left') or Input.is_action_pressed('note_down')\
				or Input.is_action_pressed('note_up') or Input.is_action_pressed('note_right')

			var boogie = (!is_player or (is_player and !holding)) and can_dance
			if hold_timer >= Conductor.step_crochet * (0.0011 * sing_duration) and boogie:
				dance()

	if !chart.is_empty():
		for i in chart: # [0] = strum time, [1] = direction, [2] = is sustain, [3] = length
			var is_hold:bool = i.length > 0
			if i.strum_time <= Conductor.song_pos:
				var suff = str(randi_range(1, 2)) if cur_char.ends_with('-speaker') else ''
				if !is_hold or i[0] + i[3] > Conductor.song_pos:
					sing(i.dir, suff, (true if !is_hold else !get_anim().contains('sing')))
				if !is_hold or i.strum_time + i.length < Conductor.song_pos: #if not sustain or sustain is finished
					chart.remove_at(chart.find(i))

func dance(forced:bool = false) -> void:
	if (special_anim and !forced) or !can_dance: return
	if looping: forced = true
	var idle:String = 'idle'
	if cur_char.contains('-dead'):
		idle = 'deathLoop'
		forced = true

	if dance_idle:
		danced = !danced
		idle = 'dance'+ ('Right' if danced else 'Left')

	play_anim(idle + idle_suffix, forced)
	hold_timer = 0
	sing_timer = 0

func sing(dir:int = 0, suffix:String = '', reset:bool = true) -> void:
	hold_timer = 0
	var to_sing:String = sing_anims[dir] + suffix
	if !has_anim(to_sing):
		if suffix == 'miss': return
		to_sing = sing_anims[dir]

	var can_reset:bool = reset or (!reset and !get_anim().begins_with('sing') and !special_anim)
	if (sing_timer >= Conductor.step_crochet / 1000.0 or can_reset):
		sing_timer = 0.0 if can_reset else (Conductor.step_crochet / 1000.0) * (1 * get_process_delta_time())
		play_anim(to_sing, true)

func flip_char() -> void:
	scale.x *= -1
	position.x += width
	focus_offsets.x -= width / 1.2
	swap_sing('singLEFT', 'singRIGHT')

func swap_sing(anim1:String, anim2:String) -> void:
	if !sing_anims.has(anim1) or !sing_anims.has(anim2): return
	var index1 = sing_anims.find(anim1)
	var index2 = sing_anims.find(anim2)
	sing_anims[index1] = anim2
	sing_anims[index2] = anim1

func play_anim(anim:String, forced:bool = false, reversed:bool = false) -> void:
	if ignore_anims: return
	if forced_suffix.length() > 0:
		anim += forced_suffix
	if !has_anim(anim):
		return printerr(anim +' doesnt exist on '+ cur_char)

	looping = false
	special_anim = false
	anim_timer = -1.0

	if is_atlas:
		atlas.play_anim(anim, forced)
	else:
		if reversed:
			play_backwards(anim)
		else:
			play(anim)
		if forced:
			frame = sprite_frames.get_frame_count(anim) - 1 if reversed else 0

	var anim_offset:Vector2 = Vector2.ZERO
	if offsets.has(anim):
		anim_offset = Vector2(offsets[anim][0], offsets[anim][1])
	offset = anim_offset
	flip_h = flippers.get(anim, false)

func get_anim() -> String:
	return atlas.cur_anim if is_atlas else animation

func get_cam_pos() -> Vector2:
	var midpoint = Vector2(global_position.x + width / 2.0, global_position.y + height / 2.0)
	var pos := Vector2(midpoint.x + (-100 if is_player else 150), midpoint.y - 100)
	return (pos + focus_offsets)

func set_stuff() -> void:
	var anim:String = 'danceLeft' if dance_idle else 'idle'
	if has_anim('deathStart') and !has_anim(anim): anim = 'deathStart' # if its a death char
	if has_anim(anim):
		if is_atlas: return # fuck if i know how to get width and height yet
		#var total:int = sprite_frames.get_frame_count(anim) - 1 # last anim is probably the most upright
		width = sprite_frames.get_frame_texture(anim, 0).get_width()
		height = sprite_frames.get_frame_texture(anim, 0).get_height()

func has_anim(anim:String) -> bool:
	if is_atlas: return atlas._added_anims.has(anim)
	return sprite_frames.has_animation(anim) if sprite_frames else false

func add_anim(anim_name:String, prefix:String = '', frames:Array = [], fps:int = 24, loop:bool = false) -> void:
	if is_atlas:
		if prefix.is_empty(): atlas.add_anim_by_frames(anim_name, frames, fps, loop)
		else: atlas.add_anim_by_symbol(anim_name, prefix, frames, fps, loop)
		return

	var got_prefix:String = Util.get_closest_anim(sprite_frames, prefix)
	var _spr := sprite_frames
	if !has_anim(anim_name):
		if got_prefix.is_empty(): return print('No Prefix Found!')
		_spr.duplicate_animation(got_prefix, anim_name)

	_spr.set_animation_speed(anim_name, fps)
	_spr.set_animation_loop(anim_name, loop)
	if !frames.is_empty():
		var anim_textures:Array[Texture2D] = []
		for i:int in _spr.get_frame_count(anim_name):
			anim_textures.append(_spr.get_frame_texture(anim_name, i))
		_spr.clear(anim_name)
		for frm in frames:
			if anim_textures.size() - 1 >= frm:
				sprite_frames.add_frame(anim_name, anim_textures[int(frm)])
		anim_textures.clear()

	#print('added animation ', str([anim_name, prefix, frames, loop]))
	#else:
	#	sprite_frames.rename_animation(got_prefix, anim_name)

static func get_closest(char_name:String = 'bf') -> String: # if theres no character named "pico-but-devil" itll just use "pico"
	var char_list = DirAccess.get_files_at('res://assets/data/characters')
	for file in char_list:
		file = file.replace('.json', '')
		if char_name.to_lower().contains(file): return file # i might be stupid

	for i in char_name.split('-'): # get more specific and stop caring
		for file in char_list:
			file = file.replace('.json', '')
			if i.to_lower().contains(file): return file
	return 'bf'

func get_frame_count(anim:String) -> int:
	return sprite_frames.get_frame_count(anim) if !is_atlas else atlas.get_frame_count(anim)

func cache_char(to_cache:String) -> void:
	if !ResourceLoader.exists('res://assets/data/characters/%s.json' % to_cache):
		to_cache = get_closest(to_cache)
	if char_cache.has(to_cache): return

	json = JsonHandler.get_character(to_cache)
	if json.has('no_antialiasing'): json = Legacy.fix_json(json)
	if json.has('assetPath'): json = VSlice.fix_json(json)

	var path = json.path +'.res'
	if !ResourceLoader.exists('res://assets/images/'+ path):
		return printerr('No .res file to cache: '+ path)

	char_cache[to_cache] = ResourceLoader.load('res://assets/images/'+ path)
	print('cached '+ to_cache)

func copy(from:Character) -> void:
	for i in from.get_script().get_script_property_list():
		if i.name in self: set(i.name, from.get(i.name))
	sprite_frames = from.sprite_frames
	position = from.position
	scale = from.scale
	antialiasing = from.antialiasing
