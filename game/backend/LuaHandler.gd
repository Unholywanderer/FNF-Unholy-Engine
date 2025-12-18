extends Node2D

enum RET_TYPES {STOP, CONTINUE}
var cached_items:Dictionary = {}
var active_lua:Array[LuaEx] = []
var active:bool = true
var script_vars:Dictionary[String, Variant] = {}

func add_script(script:String) -> void:
	if !script.ends_with('.lua'): script += '.lua'

	#TODO maybe figure out way to do something like 'import'
	var lua = LuaEx.new()
	lua.script_path = script
	lua.bind_libraries(["base", "table", "string", "math"])

	var SCENE = Game.scene
	## Variables ##
	lua.add("Game", SCENE) # current scene
	lua.add("STOP", RET_TYPES.STOP)
	lua.add("CONTINUE", RET_TYPES.CONTINUE)

	## Objects ##
	lua.add("Conductor", Conductor)
	lua.add("Character", Character)
	lua.add("Sprite", LuaSprite)
	lua.add("XMLSprite", LuaSparrowSprite) # WIP
	lua.add("ResSprite", LuaResSprite)
	lua.add("Chart", Chart)

	if SCENE.name == "Play_Scene":
		lua.add("song_root", JsonHandler.song_root)
		lua.add("variant", JsonHandler.song_variant.substr(1))
		lua.add("move_cam", SCENE.move_cam)
		lua.add("UI", SCENE.ui)
		lua.add("boyfriend", SCENE.boyfriend)
		lua.add("gf", SCENE.gf)
		lua.add("dad", SCENE.dad)

		lua.add("add_char", add_character)

	## Lua Functions ##
	# Layering #
	lua.add("add", SCENE.add_child)
	lua.add("move", move_obj)
	lua.add("get_layer", get_layer)

	# Helpers n random shit #
	lua.add("tween", lua_tween)
	lua.add("parse_json", parse_json)
	lua.add("play_sound", Audio.play_sound)
	lua.add("play_music", Audio.play_music)
	lua.add("cache", cache_file)
	lua.add("file_exists", file_exists)
	lua.add("get_cache", get_cached_file)
	lua.add("switch_scene", switch_scene)
	lua.add("key_pressed", key_pressed)
	lua.add("to_str", to_str)

	# Shaders #
	lua.add("load_shader", load_shader)
	lua.add("set_shader", set_shader)
	lua.add("set_param", set_param)

	#lua.push_variant("import", add_variant)

	if !load_lua(lua, script, !script.begins_with('C:/')): return
	print(lua.script_path +' is loaded')

	if !active_lua.has(lua):
		active_lua.append(lua)

func remove_all():
	for lua in active_lua:
		if lua.global: continue # dont remove global ones
		lua.unreference()
	active_lua.clear()
	cached_items.clear()

func reload_scripts():
	for lua in active_lua:
		load_lua(lua, lua.script_path)

func add_variant(vari_name:String, variant:Variant) -> void:
	for i in active_lua:
		i.push_variant(vari_name, variant)

func load_lua(lua:LuaEx, path:String, internal:bool = true) -> bool:
	var lua_start:String = 'res://assets/' if internal else ''
	var err = lua.do_file(lua_start + path)
	if err is LuaError:
		printerr(err.message)
		var er_type = err.message.split(']')[0].replace('[', '').strip_edges()
		var er_path = err.message.split('assets/')[1].strip_edges()
		OS.alert('../'+ er_path, er_type +'!')
		if active_lua.has(lua):
			active_lua.remove_at(active_lua.find(lua))
		return false
	return true

func call_func(_func:String, args:Array = []) -> RET_TYPES:
	if _func.length() == 0: return RET_TYPES.CONTINUE
	var ret_val:RET_TYPES = RET_TYPES.CONTINUE
	for i in active_lua:
		if !i.function_exists(_func): continue
		var new_val = i.call_function(_func, args)
		if new_val is RET_TYPES: ret_val = new_val
	return ret_val

## FUNCTIONS FO LUA CRIPTS 😎😎
func pain(x):
	return (x^x^x^x^x^x^x^x^x^x^x^x^x^x)^-x

func add_obj(obj:Variant = null, to_group:Variant = null):
	if obj == null: return
	if to_group == null: to_group = Game.scene
	to_group.add_child(obj)

func get_layer(obj):
	if obj is int: return obj
	return obj.get_index()

func move_obj(obj:Variant, indx):
	var add_to = Game.scene
	if indx is Character and Game.scene.name == 'Play_Scene':
		if Game.scene.stage.has_node('CharGroup'):
			add_to = Game.scene.stage.get_node('CharGroup')
	if indx is Node2D:
		indx = indx.get_index() # assume its an object and get its' layer
	add_to.move_child(obj, indx)

func file_exists(file:String): return Util.file_exists(file)
func cache_file(tag:String, file_path:String):
	if cached_items.has(tag):
		print(tag +' already cached, overwritting')
	var check = file_path.split('/')
	if check[-1].split('.').is_empty():
		printerr('file type not specified, assuming ".png"')
		file_path += '.png'

	if ResourceLoader.exists('res://assets/'+ file_path):
		cached_items[tag] = load('res://assets/'+ file_path)

func is_cached(tag:String): return cached_items.has(tag) and cached_items.get(tag) != null
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

func lua_tween(obj:Variant, prop:String, to_val:Variant, dur:float, t:String = '', e:String = '') -> void:
	if obj == null: return Alert.make_alert('Tween Error\nobj is null!')
	if typeof(obj) == TYPE_STRING: obj = Game.scene.get(obj)
	Util.quick_tween(obj, prop.replace('.', ':'), to_val, dur,\
	 Util.trans_from_string(t), Util.ease_from_string(e))

func key_pressed(key:String = '') -> bool:
	if InputMap.has_action(key):
		return Input.is_action_just_pressed(key)
	var actual_key := OS.find_keycode_from_string(key.capitalize())
	return Input.is_key_pressed(actual_key)

func to_str(thing:Variant) -> String:
	return str(thing)

func switch_scene(new_scene:String = '', skip_trans:bool = false) -> void:
	Game.switch_scene(new_scene, skip_trans)

#func add_variant(variant:String):
#	if !variant.is_empty():
#		for lua in active_lua:
#			lua.push_variant(variant, load('res://game/'+ variant.replace('.', '/') +'.gd'))

func add_character(Char:Character, _layer:String = '') -> void:
	var layer_indx:int = -1
	var add_to:Node2D = Game.scene.stage.get_node('CharGroup') \
	 if Game.scene.stage.has_node('CharGroup') else Game.scene

	match _layer.to_lower().strip_edges():
		'boyfriend', 'gf', 'dad':
			layer_indx = add_to.get(_layer).get_index()

	Game.scene.characters.append(Char)
	add_to.add_child(Char)
	if layer_indx > -1:
		add_to.move_child(Char, layer_indx)

func parse_json(path:String) -> Dictionary:
	if !path.ends_with('.json'): path += '.json'
	if !ResourceLoader.exists('res://assets/'+ path):
		Alert.make_alert('No .json at path\n"'+ path +'"', Alert.ERROR)
		return {}
	var le_json = FileAccess.get_file_as_string('res://assets/'+ path)
	return JSON.parse_string(le_json)

## LUA OBJECTS
class LuaSprite extends Sprite2D:
	func _init(pos:Vector2 = Vector2.ZERO, spr:String = ''):
		if !spr.is_empty():
			load_texture(spr)
		position = pos

	func load_texture(spr:String):
		if spr.is_empty(): return
		texture = load('res://assets/images/'+ spr +'.png')

class LuaResSprite extends AnimatedSprite2D:
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

class LuaSparrowSprite extends SparrowSprite:
	var offsets:Dictionary = {}
	func _init(spr:String = '') -> void:
		super(spr)


class LuaEx extends LuaAPI:
	var global:bool = false # later
	var active:bool = false
	var script_path:String = ''
	func _notification(what:int) -> void:
		if what == NOTIFICATION_PREDELETE: print("good-bye")

	func add(vari:String, item:Variant) -> void:
		if vari.is_empty() or item == null: return printerr('COULD NOT ADD '+ vari)
		push_variant(vari, item)
