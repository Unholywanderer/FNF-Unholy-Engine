class_name Character; extends AnimatedSprite2D;

var json
var chart:Array = []
var offsets:Dictionary = {}
var flippers:Dictionary = {}
var speaker_data:Dictionary = {}
var focus_offsets:Vector2 = Vector2.ZERO # cam offset type shit

var cur_char:String = ''
var icon:String = 'bf'
var death_char:String = 'bf-dead'

var debug:bool = false
var is_player:bool = false

var idle_suffix:String = ''
var forced_suffix:String = '' # if set, every anim will use it
var can_dance:bool = true
var looping:bool = false

var dance_idle:bool = false
var danced:bool = false
var dance_beat:int = 2 # dance every %dance_beat%

var hold_timer:float = 0.0
var sing_duration:float = 4.0
var sing_timer:float = 0.0 # for anim looping with sustains

var last_anim:StringName = ''
var special_anim:bool = false:
	set(spec): 
		if spec: last_anim = animation
		special_anim = spec
var anim_timer:float = -1.0: # play an anim for a certain amount of time
	set(time):
		anim_timer = time
		if !special_anim and time > 0:
			special_anim = true

var on_anim_finished:Callable = func():
	special_anim = false
	can_dance = true
	dance()
	animation_finished.disconnect(on_anim_finished)

var anim_finished:bool:
	get: return frame == sprite_frames.get_frame_count(animation) - 1
	
var width:float = 0.0:
	get: return width * abs(scale.x)
var height:float = 0.0:
	get: return height * abs(scale.y)

var antialiasing:bool = true:
	get: return texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
	set(anti): texture_filter = Game.get_alias(anti)

var sing_anims:PackedStringArray = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT']

func _init(pos:Vector2 = Vector2.ZERO, char:String = 'bf', player:bool = false):
	centered = false
	is_player = player
	position = pos
	load_char(char)
	
func load_char(new_char:String = 'bf') -> void:
	if new_char == cur_char or new_char.is_empty():
		print(new_char +' already loaded')
		return
		
	cur_char = new_char
	if !ResourceLoader.exists('res://assets/data/characters/%s.json' % cur_char):
		var replace_char = get_closest(cur_char)
		print_rich('No JSON found for: '+ cur_char +'\n', '[color=red]'+ cur_char +' [color=yellow]-> [color=green]'+ replace_char)
		cur_char = replace_char
	
	json = JsonHandler.get_character(cur_char) # get offsets and anim names...
	if json.has('no_antialiasing'):
		json = Legacy.fix_json(json)
		
	var path = json.path +'.res'
	if !ResourceLoader.exists('res://assets/images/'+ path): # json exists, but theres no res file
		printerr('No .res file found: '+ path)
		path = 'characters/bf/char.res'
		
	sprite_frames = ResourceLoader.load('res://assets/images/'+ path)
	
	offsets.clear()
	for anim in json.animations:
		offsets[anim.name] = anim.offsets
		flippers[anim.name] = anim.get('flipX')
	
	icon = json.icon
	scale = Vector2(json.scale, json.scale)
	antialiasing = json.antialiasing
	position.x += json.pos_offset[0]
	position.y += json.pos_offset[1]
	focus_offsets.x = json.cam_offset[0]
	focus_offsets.y = json.cam_offset[1]
	
	speaker_data.clear()
	if json.has('speaker'):
		speaker_data = json.speaker
	
	dance_idle = offsets.has('danceLeft') and offsets.has('danceRight')
	dance_beat = 1 if dance_idle else 2
	
	match(cur_char):
		'senpai':
			dance_beat = 2
		'senpai-angry':
			forced_suffix = '-alt' # boooo
		'pico-speaker', 'otis-speaker':
			animation_changed.connect(func(): can_dance = animation == 'idle')
			animation_finished.connect(func(): if animation != 'idle': play_anim('idle'))
			can_dance = false
			sing_anims = ['shootLeft', 'shootLeft', 'shootRight', 'shootRight']
			play_anim('idle')
			#frame = sprite_frames.get_frame_count('shootRight1') - 4
	
	dance()
	set_stuff()
	
	if !is_player == json.facing_left:
		flip_char()
		
	print('loaded '+ cur_char)

func _process(delta):
	if debug: return
	if special_anim:
		if anim_timer == -1.0:
			if !animation_finished.is_connected(on_anim_finished):
				animation_finished.connect(on_anim_finished)
		else:
			anim_timer = max(anim_timer - delta, 0)
			if anim_timer <= 0.0:
				special_anim = false
				if animation == last_anim:
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
	
	if cur_char.contains('-car') and offsets.has(animation +'-loop') and \
	  frame >= sprite_frames.get_frame_count(animation) - 1:
		looping = true
		frame = sprite_frames.get_frame_count(animation) - 5
		
	if !chart.is_empty():
		for i in chart: # [0] = strum time, [1] = direction, [2] = is sustain, [3] = length
			var dir = int(i[1]) % 4
			if i[2]:
				if i[0] <= Conductor.song_pos and i[0] + i[3] > Conductor.song_pos:
					sing(dir, '', false)
				if Conductor.song_pos > i[0] + i[3]: # sustain should be finished
					chart.remove_at(chart.find(i))
			else:
				if i[0] <= Conductor.song_pos:
					var suff = str(randi_range(1, 2)) if cur_char.ends_with('-speaker') else ''
					sing(dir, suff)
					chart.remove_at(chart.find(i))

func dance(forced:bool = false) -> void:
	if special_anim or !can_dance: return
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
		
	if sing_timer >= Conductor.step_crochet / 1000.0 or reset:
		sing_timer = 0.0 #if reset else Conductor.step_crochet / 1000.0
		play_anim(to_sing, true)

func flip_char() -> void:
	scale.x *= -1
	position.x += width
	focus_offsets.x -= width / 1.5
	#if (!is_player and sing_anims[0] == 'singLEFT') or (is_player and sing_anims[0] == 'singRIGHT'):
	swap_sing('singLEFT', 'singRIGHT')

func swap_sing(anim1:String, anim2:String) -> void:
	if !sing_anims.has(anim1) or !sing_anims.has(anim2): return
	var index1 = sing_anims.find(anim1)
	var index2 = sing_anims.find(anim2)
	sing_anims[index1] = anim2
	sing_anims[index2] = anim1

func play_anim(anim:String, forced:bool = false, reversed:bool = false) -> void:
	if forced_suffix.length() > 0: 
		anim += forced_suffix
	if !has_anim(anim): 
		return printerr(anim +' doesnt exist on '+ cur_char)
	
	looping = false
	special_anim = false
	anim_timer = -1.0
	
	if reversed:
		play_backwards(anim)
	else:
		play(anim)
	if forced: 
		frame = sprite_frames.get_frame_count(anim) - 1 if reversed else 0 

	var anim_offset:Vector2 = Vector2.ZERO
	if offsets.has(anim):
		anim_offset = Vector2(offsets[anim][0], offsets[anim][1])
		flip_h = flippers[anim] if flippers[anim] else false
	offset = anim_offset

func get_cam_pos() -> Vector2:
	var midpoint = Vector2(position.x + width / 2.0, position.y + height / 2.0)
	var pos:= Vector2(midpoint.x + (-100 if is_player else 150), midpoint.y - 100)
	return (pos + focus_offsets)
	
func set_stuff() -> void:
	var anim:String = 'danceLeft' if dance_idle else 'idle'
	if has_anim('deathStart') and !has_anim(anim): anim = 'deathStart' # if its a death char
	if has_anim(anim):
		#var total:int = sprite_frames.get_frame_count(anim) - 1 # last anim is probably the most upright
		width = sprite_frames.get_frame_texture(anim, 0).get_width()
		height = sprite_frames.get_frame_texture(anim, 0).get_height()

func has_anim(anim:String) -> bool:
	return sprite_frames.has_animation(anim) if sprite_frames != null else false

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

func copy(from:Character) -> void:
	for i in from.get_script().get_script_property_list():
		if i.name in self: set(i.name, from.get(i.name))
	sprite_frames = from.sprite_frames
	position = from.position
	scale = from.scale
	antialiasing = from.antialiasing
#func get_anim(anim:String): # get the animation from the json file
#	if json == null: return anim
#	for name in json.animations:
#		if json.anim == anim: return json.name
#	return anim
