class_name SparrowSprite; extends Node2D;
## A Sprite2D that uses a sparrow atlas (xml) to play animations
## Severely unfinished and prone to breaking
var sprite:Sprite2D = Sprite2D.new()
var _anim_in_progress:bool = false

var framerate:float = 24.0
var cur_anim:String = ''
var cur_frame:int = -1:
	set(new_frame):
		var cur_data:Array = _prefixes[_cur_prefix]
		_anim_in_progress = new_frame < cur_data.size()

		if _anim_in_progress:
			cur_frame = clamp(new_frame, 0, cur_data.size() - 1)
		elif animations[cur_anim].loop:
			_anim_in_progress = true
			cur_frame = 0

		sprite.region_rect = cur_data[cur_frame].box
		sprite.offset = offset - cur_data[cur_frame].frame_offsets

var flip_h:bool:
	set(flip): sprite.flip_h = flip
	get: return sprite.flip_h

var flip_v:bool:
	set(flip): sprite.flip_v = flip
	get: return sprite.flip_v

var offset:Vector2 = Vector2.ZERO:
	set(new_off):
		offset = new_off # do this so the offset actually updates on the animation when you set it
		sprite.offset = offset - _prefixes[_cur_prefix][cur_frame].frame_offsets

## Holds the parsed XML info, like the frame positions,
## rotation, offsets, and the like for each found prefix
var _prefixes:Dictionary[String, Array] = {}

## The current prefix i guess
var _cur_prefix:String = ''

## Holds the actual added animations that the user has added
var animations:Dictionary[String, AnimData] = {}

# order is most likely [name, x, y, width, height, frameX, frameY, frameWidth, frameHeight]
func _init(spr:String = '') -> void:
	add_child(sprite)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	parse_xml(spr)

## Parses an XML file with the path to the sprite, starts in 'images/'
func parse_xml(path_to:String = '') -> void:
	var path = 'res://assets/images/%s' % [path_to]
	var found_texture:Texture2D
	if ResourceLoader.exists(path +'.png'):
		found_texture = load(path +'.png')
	elif FileAccess.file_exists(Game.exe_path +'mods/images/'+ path_to +'.png'):
		path = Game.exe_path +'mods/images/'+ path_to
		var new_tex:Image = Image.load_from_file(path +'.png')
		found_texture = ImageTexture.create_from_image(new_tex)

	if found_texture == null:
		return printerr('No Image/Sprite found at "'+ path_to +'"!')

	sprite.texture = found_texture # load(path +'.png')
	animations.clear()
	_prefixes.clear()

	var xml_file:XMLParser = XMLParser.new()
	xml_file.open(path +'.xml')

	while xml_file.read() != ERR_FILE_EOF:
		if xml_file.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name:String = xml_file.get_node_name()
			if node_name == 'SubTexture':
				var prefix:String = xml_file.get_named_attribute_value('name')
				prefix = prefix.left(len(prefix) - 4)
				if !_prefixes.has(prefix): _prefixes[prefix] = [] # create an array

				var xml_data:XMLData = XMLData.new()
				for i in ['x', 'y', 'width', 'height', 'frameX', 'frameY', 'frameWidth', 'frameHeight', 'rotated']:
					var got:String = xml_file.get_named_attribute_value_safe(i)
					if got.is_empty(): continue
					# if it exists, add the values to the data
					# would probably be best if the bounding box was added to the data itself
					match typeof(xml_data.get(i)):
						TYPE_FLOAT: xml_data.set(i, got.to_float())
						TYPE_BOOL: xml_data.set(i, got == 'true')
						_: xml_data.set(i, got)

				xml_data.box = Rect2(
					Vector2(xml_data.x, xml_data.y), Vector2(xml_data.width, xml_data.height)
				)
				xml_data.frame_offsets = Vector2(
					xml_data.frameX, xml_data.frameY
				)
				_prefixes[prefix].append(xml_data)

#var last_frame_data
#var last_rect:Rect2
#func get_bound_box() -> Rect2:
#	var _frame_data #= _prefixes[cur_anim][cur_frame]
#	if last_frame_data == _frame_data: return last_rect
#	last_frame_data = _frame_data
#	var rect:Rect2 = Rect2(
#		Vector2(_frame_data.x.to_float(), _frame_data.y.to_float()),
#		Vector2(_frame_data.width.to_float(), _frame_data.height.to_float())
#	)

#	if _frame_data.has('frameX'):
#		var frame_size_data = Vector2(
#			_frame_data.frameWidth.to_float(), _frame_data.frameHeight.to_float()
#		)
#		var frame_offsets = Vector2(
#			_frame_data.frameX.to_float(), _frame_data.frameY.to_float()
#		)
#		sprite.offset = -frame_offsets

#		if frame_size_data == Vector2.ZERO:
#			frame_size_data = rect.size

	#margin = Rect2(
	#	Vector2(
	#		-_frame_data.frameX.to_float(),
	#		-_frame_data.frameY.to_float()
	#	),
	#	Vector2(
	#		_frame_data.frameWidth.to_float() - rect.size.x,
	#		_frame_data.frameHeight.to_float() - rect.size.y
	#	)
	#)

	#if margin.size.x < abs(margin.position.x):
	#	margin.size.x = abs(margin.position.x)
	#if margin.size.y < abs(margin.position.y):
	#	margin.size.y = abs(margin.position.y)
#	last_rect = rect
#	return rect

func add_by_prefix(new_name:String, prefix:String, fps:float = 24, loop:bool = false) -> void:
	if _prefixes.has(prefix):
		if animations.has(new_name): print(prefix +' already has name, overwriting')
		var new_anim = AnimData.new()
		new_anim.anim = new_name
		new_anim.prefix = prefix
		new_anim.framerate = fps
		new_anim.loop = loop
		animations[new_name] = new_anim
		print('added anim '+ new_name +': '+ prefix)
		if animations.size() == 1:
			play_anim(new_name)
		return

	printerr('There is no "'+ prefix +'" in the xml, check for misspellings')

func find_anim(anim:String) -> String: # find animation from an alias
	var returnin:String = ''
	var list:Array = _prefixes.keys()
	if animations.has(anim):
		var id:int = list.find(animations[anim])
		returnin = list[id]
	if returnin == '': returnin = list[0]
	return returnin

func play_anim(anim_name:String, forced:bool = false, _reversed:bool = false):
	_cur_prefix = animations[anim_name].prefix
	if _cur_prefix.is_empty(): _cur_prefix = cur_anim

	framerate = animations[anim_name].framerate
	if !forced:
		forced = anim_name != cur_anim or !_anim_in_progress
	cur_anim = anim_name
	_anim_in_progress = true
	if forced: cur_frame = 0

var frame_limit:float = 0.0
func _process(delta:float) -> void:
	if _anim_in_progress:
		frame_limit += delta
		if frame_limit >= 1.0 / framerate:
			frame_limit = 0.0
			cur_frame += 1

class AnimData extends Resource:
	var anim:String = ''
	var prefix:String = ''
	var framerate:float = 24.0
	var frames:Array = []
	var loop:bool = false

class XMLData extends Resource:
	var box:Rect2 = Rect2()
	var frame_offsets:Vector2 = Vector2.ZERO
	var x:float
	var y:float
	var width:float
	var height:float
	var frameX:float
	var frameY:float
	var frameWidth:float
	var frameHeight:float
	var rotated:bool
