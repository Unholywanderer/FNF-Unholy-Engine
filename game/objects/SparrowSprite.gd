class_name SparrowSprite; extends Sprite2D;
## A Sprite2D that uses a sparrow atlas (xml) to play animations
## Severely unfinished and prone to breaking
var _anim_in_progress:bool = false

var looping:bool = false
var framerate:float = 24.0
var cur_anim:String = ''
var cur_frame:int = -1:
	set(new_frame):
		_anim_in_progress = new_frame < prefixes[cur_anim].size()
		#print(new_frame, ' ', prefixes[cur_anim].size())
		if _anim_in_progress:
			cur_frame = clamp(new_frame, 0, prefixes[cur_anim].size() - 1)
			region_rect = get_bound_box()
		elif looping:
			_anim_in_progress = true
			cur_frame = 0
			region_rect = get_bound_box()
			
var xml_file:XMLParser = XMLParser.new()

var prefixes:Dictionary = {}
var aliases:Dictionary = {}
var par_format:Dictionary = {
	'frame': 0, 'x': 0, 'y': 0, 'width': 0, 'height': 0,
	'frameX': 0, 'frameY': 0, 'frameWidth': 0, 'frameHeight': 0
}

# want it to look through the xml file
# list each found prefix in a dictionary
# each prefix in the dictionary should be an array of an array of the xml's frame data
# example: var lol = {'SingRight': [[x, y, width, height, etc...], [x, y, width, height, etc...]]
#NOTE (actually, it could be an array of dictionaries, to allow for .x, .width things)
# when you add/give an alias to said prefix, it should grab the matched prefix from the dictionary,
# and use a rect to clip the image according to the data

# order is most likely [name, x, y, width, height, frameX, frameY, frameWidth, frameHeight]
func _init(spr:String) -> void:
	var path = 'res://assets/images/%s' % [spr]
	texture = load(path +'.png')
	centered = false
	region_enabled = true
	region_filter_clip_enabled = true
	xml_file.open(path +'.xml')
	while xml_file.read() != ERR_FILE_EOF:
		if xml_file.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name = xml_file.get_node_name() 
			if node_name == 'SubTexture':
				var prefix = xml_file.get_named_attribute_value('name')
				prefix = prefix.left(len(prefix) - 4)
				if !prefixes.has(prefix): prefixes[prefix] = [] # create an array
				
				var attributes = {}
				for i in ['x', 'y', 'width', 'height', 'frameX', 'frameY', 'frameWidth', 'frameHeight', 'rotated']:
					var got = xml_file.get_named_attribute_value_safe(i)
					if got.length() > 0: # if it exists, add the value to attributes
						attributes[i] = got
				prefixes[prefix].append(attributes)
				
var last_frame_data
var last_rect:Rect2
func get_bound_box() -> Rect2:
	var _frame_data = prefixes[cur_anim][cur_frame]
	if last_frame_data == _frame_data: return last_rect
	last_frame_data = _frame_data
	var rect:Rect2 = Rect2(
		Vector2(_frame_data.x.to_float(), _frame_data.y.to_float()),
		Vector2(_frame_data.width.to_float(), _frame_data.height.to_float())
	)

	if _frame_data.has('frameX'):
		var frame_size_data = Vector2(
			_frame_data.frameWidth.to_float(), _frame_data.frameHeight.to_float()
		)
		var frame_offsets = Vector2(
			_frame_data.frameX.to_float(), _frame_data.frameY.to_float()
		)
		offset = -frame_offsets
		
		if frame_size_data == Vector2.ZERO:
			frame_size_data = rect.size
	
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
	last_rect = rect
	return rect
	
func add_by_prefix(prefix:String, new_name:String):
	if aliases.has(new_name): print(prefix +' already has name, overwriting')
	if prefixes.has(prefix):
		aliases[new_name] = prefix
		print('added anim '+ new_name +': '+ prefix)
	else:
		printerr('there is no "'+ prefix +'" in the xml')
	
func find_anim(anim:String): # find animation from an alias
	var returnin:String = ''
	var list:Array = prefixes.keys()
	if aliases.has(anim): 
		var id:int = list.find(aliases[anim])
		returnin = list[id]
	if returnin == '': returnin = list[0]
	return returnin

func play_anim(anim_name:String, forced:bool = false, fps:float = 24.0, reversed:bool = false):
	var got_name:String = find_anim(anim_name)
	print(got_name)
	framerate = fps
	if !forced:
		forced = got_name != cur_anim or !_anim_in_progress
	cur_anim = got_name
	_anim_in_progress = true
	if forced: cur_frame = 0
	

var frame_limit:float = 0.0
func _process(delta:float) -> void:
	if _anim_in_progress:
		frame_limit += delta
		if frame_limit >= 1.0 / framerate:
			frame_limit = 0.0
			cur_frame += 1
