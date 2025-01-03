extends Node2D

enum RET_TYPES {STOP, CONTINUE}
var cached_items:Dictionary = {}
var active_lua:Array = []
var active:bool = true

func add_script(script:String) -> void:
	if !script.ends_with('.lua'): script += '.lua'
	# okay, it seems that i have fixed the random crashing that could happen from luas
	# but im not 100% sure, so ill just note this down
	#TODO maybe figure out way to do something like 'import'
	var lua = LuaEx.new()
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
		lua.push_variant("Chart", Chart)
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
	lua.push_variant("get_cache", get_cached_file)
	#lua.push_variant("import", add_variant)

	var err = lua.do_file('res://assets/'+ script)
	if err is LuaError:
		printerr(err.message)
		var er_type = err.message.split(']')[0].replace('[', '').strip_edges()
		var er_path = err.message.split('assets/')[1].strip_edges()
		OS.alert('../'+ er_path, er_type +'!')
		return
		
	if !active_lua.has(lua):
		active_lua.append(lua)
	
func remove_all():
	for lua in active_lua:
		lua.unreference()
	active_lua.clear()

func call_func(_func:String, args:Array = []):
	if _func.length() == 0: return
	var ret_val = null
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
	if indx is Node2D: indx = indx.get_index() # assume its an object and get it's layer
	Game.scene.move_child(obj, indx)

func cache_file(tag:String, file_path:String):
	if cached_items.has(tag):
		print(tag +' already cached, overwriting')
	var check = file_path.split('/')
	if check[check.size() - 1].split('.').size() == 0:
		printerr('file type not specified, assuming ".png"')
		file_path += '.png'
		
	cached_items[tag] = load('res://assets/'+ file_path)

func get_cached_file(tag:String):
	return cached_items[tag] if cached_items.has(tag) else load('res://assets/images/logoBumpin.png')
	
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
		printerr('Nope')
		return
	var le_json = FileAccess.open('res://assets/'+ path, FileAccess.READ).get_as_text()
	return JSON.parse_string(le_json)

func makeLuaSprite(_t, _sp, _x, _y):
	get_tree().exit()

func setProperty(_g, _p):
	return IP.get_local_addresses()

## LUA OBJECTS
class LuaSprite extends Sprite2D:
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
	func _notification(what:int) -> void:
		match what:
			NOTIFICATION_PREDELETE:
				print("good-bye")
