extends Node2D

enum RET_TYPES {STOP, CONTINUE}
var cached_items:Dictionary = {}
var active_lua:Array = []
var active:bool = true

func add_script(script:String) -> void:
	if !script.ends_with('.lua'): script += '.lua'
	
	#TODO maybe figure out way to do something like 'import'
	var lua = LuaEx.new()
	lua.script_path = script
	lua.bind_libraries(["base", "table", "string", "math"])
	
	var SCENE = Game.scene
	## Variables ##
	lua.push_variant("Game", SCENE) # current scene
	lua.push_variant("STOP", RET_TYPES.STOP)
	lua.push_variant("CONTINUE", RET_TYPES.CONTINUE)
	
	## Objects ##
	lua.push_variant("Conductor", Conductor)
	lua.push_variant("Character", Character)
	lua.push_variant("Sprite", LuaSprite)
	lua.push_variant("AnimSprite", SparrowSprite) # WIP
	
	if SCENE.name == "Play_Scene":
		lua.push_variant("song_root", JsonHandler.song_root)
		lua.push_variant("variant", JsonHandler.song_variant.substr(1))
		lua.push_variant("Chart", Chart)
		lua.push_variant("move_cam", SCENE.move_cam)
		lua.push_variant("UI", SCENE.ui)
		lua.push_variant("boyfriend", SCENE.boyfriend)
		lua.push_variant("gf", SCENE.gf)
		lua.push_variant("dad", SCENE.dad)
		
		lua.push_variant("add_char", add_character)
	
	## Lua Functions ##
	# Layering #
	lua.push_variant("add", SCENE.add_child)
	lua.push_variant("move", move_obj)
	lua.push_variant("get_layer", get_layer)
	
	# Helpers n random shit #
	lua.push_variant("parse_json", parse_json)
	lua.push_variant("play_sound", Audio.play_sound)
	lua.push_variant("play_music", Audio.play_music)
	lua.push_variant("cache", cache_file)
	lua.push_variant("file_exists", file_exists)
	lua.push_variant("get_cache", get_cached_file)
	# Shaders #
	lua.push_variant("load_shader", load_shader)
	lua.push_variant("set_shader", set_shader)
	lua.push_variant("set_param", set_param)
	
	#lua.push_variant("import", add_variant)
	
	if !load_lua(lua, script): return
	print(lua.script_path +' is loaded')
		
	if !active_lua.has(lua):
		active_lua.append(lua)
	
func remove_all():
	for lua in active_lua:
		lua.unreference()
	active_lua.clear()
	cached_items.clear()

func reload_scripts():
	for lua in active_lua:
		load_lua(lua, lua.script_path)
		
func load_lua(lua:LuaEx, path:String) -> bool:
	var err = lua.do_file('res://assets/'+ path)
	if err is LuaError:
		printerr(err.message)
		var er_type = err.message.split(']')[0].replace('[', '').strip_edges()
		var er_path = err.message.split('assets/')[1].strip_edges()
		OS.alert('../'+ er_path, er_type +'!')
		if active_lua.has(lua):
			active_lua.remove_at(active_lua.find(lua))
		return false
	return true
			
func call_func(_func:String, args:Array = []):
	if _func.length() == 0: return 1
	var ret_val = RET_TYPES.CONTINUE
	for i in active_lua:
		if !i.function_exists(_func): continue
		ret_val = i.call_function(_func, args)
	return ret_val 
	
## FUNCTIONS FO LUA CRIPTS 😎😎
func pain(x):
	return (x^x^x^x^x^x^x^x^x^x^x^x^x^x)^-x
	
func add_obj(obj:Variant = null, to_group:Variant = null):
	if obj != null:
		if to_group != null:  pass
	add_child(obj)

func get_layer(obj):
	if obj is int: return obj
	return obj.get_index()

func move_obj(obj:Variant, indx):
	var add_to = Game.scene
	if indx is Character and Game.scene.name == 'Play_Scene':
		if Game.scene.stage.has_node('CharGroup'):
			add_to = Game.scene.stage.get_node('CharGroup')
	if indx is Node2D:
		indx = indx.get_index() # assume its an object and get it's layer
	add_to.move_child(obj, indx)

func file_exists(file:String): return ResourceLoader.exists('res://assets/'+ file)
func cache_file(tag:String, file_path:String):
	if cached_items.has(tag):
		print(tag +' already cached, overwriting')
	var check = file_path.split('/')
	if check[check.size() - 1].split('.').size() == 0:
		printerr('file type not specified, assuming ".png"')
		file_path += '.png'
		
	cached_items[tag] = load('res://assets/'+ file_path)

func is_cached(tag:String): return cached_items.has(tag)
func get_cached_file(tag:String):
	return cached_items[tag] if is_cached(tag) else load('res://assets/images/logoBumpin.png')
	
func load_shader(shader:String) -> Shader:
	var new_shader:Shader = null
	if ResourceLoader.exists('res://game/resources/shaders/'+ shader +'.gdshader'):
		cached_items[shader +'_shader'] = load('res://game/resources/shaders/'+ shader +'.gdshader')
		new_shader = cached_items[shader +'_shader']
	if new_shader == null: 
		Alert.make_alert('"%s" isn\'t a valid shader!' % [shader], Alert.WARN)
	return new_shader

func set_shader(obj:Variant, shader_name:String):
	var new_shader = ShaderMaterial.new() 
	new_shader.shader = load_shader(shader_name)
	obj.material = new_shader

func set_param(obj:Variant, param:String, new_value:Variant):
	obj.material.set_shader_parameter(param, new_value)
	
func get_param(obj:Variant, param:String):
	return obj.material.get_shader_parameter(param)
#func add_variant(variant:String):
#	if !variant.is_empty():
#		for lua in active_lua:
#			lua.push_variant(variant, load('res://game/'+ variant.replace('.', '/') +'.gd'))
			
func add_character(char:Character, _layer:String = ''):
	var layer_indx:int = -1
	var add_to = Game.scene.stage.get_node('CharGroup') if Game.scene.stage.has_node('CharGroup') else Game.scene
	
	match _layer.to_lower().strip_edges():
		'boyfriend': layer_indx = add_to.get('boyfriend').get_index()
		'gf': layer_indx = add_to.get('gf').get_index()
		'dad': layer_indx = add_to.get('dad').get_index()
		
	Game.scene.characters.append(char)
	add_to.add_child(char)
	if layer_indx > -1:
		add_to.move_child(char, layer_indx)

func parse_json(path:String):
	if !path.ends_with('.json'): path += '.json'
	if !ResourceLoader.exists('res://assets/'+ path):
		Alert.make_alert('No .json at path\n"'+ path +'"', Alert.ERROR)
		return
	var le_json = FileAccess.get_file_as_string('res://assets/'+ path)
	return JSON.parse_string(le_json)

func makeLuaSprite(_t, _sp, _x, _y):
	get_tree().exit()

func setProperty(_g, _p):
	return IP.get_local_addresses()

## LUA OBJECTS
class LuaSprite extends Sprite2D:
	func _init(spr:String, pos:Vector2 = Vector2.ZERO):
		load_texture(spr)
		position = pos
		
	func load_texture(spr:String):
		texture = load('res://assets/images/'+ spr +'.png')
		
class LuaAnimatedSprite extends AnimatedSprite2D:
	var offsets:Dictionary = {}
	func load_anims(path:String):
		offsets.clear()
		sprite_frames = load('res://assets/images/'+ path +'.res')
	
	func add_offset(anim:String, offs:Array = [0, 0]):
		offsets[anim] = Vector2(offs[0], offs[1])
	
	func play_anim(anim:String, forced:bool = true, reverse:bool = false):
		if sprite_frames.has_animation(anim):
			play(anim)
			if forced: frame = sprite_frames.get_frame_count(anim) - 1 if reverse else 0
			var da_off:Vector2 = Vector2.ZERO
			if offsets.has(anim):
				da_off = offsets[anim]
				
			offset = da_off
			
class LuaEx extends LuaAPI:
	var global:bool = false # later
	var active:bool = false # later
	var script_path:String = ''
	func _notification(what:int) -> void:
		match what:
			NOTIFICATION_PREDELETE:
				print("good-bye")
