@tool
@icon('animate_symbol.svg')
class_name AnimateSymbol extends Node2D
## Node that lets you play Adobe Animate Texture Atlases
## in Godot.


## The folder path to the atlas that is loaded.
## [br][br][b]Note[/b]: This automatically reloads the atlas when
## changed.
@export_dir var atlas: String:
	set(v):
		atlas = v
		load_atlas(atlas)


## The current frame of the animation.
## [br][br][b]Note[/b]: This automatically redraws the entire
## atlas when changed.
@export var frame: int = 0:
	set(v):
		if loop_frame > -1 and v > _timeline.length - 1:
			v = loop_frame
		frame = v
		frame_changed.emit(frame)
		queue_redraw()

var loop_frame:int = -1
## The current symbol used by the animation. Empty uses the timeline symbol.
## [br][br][b]Note[/b]: This automatically sets [member frame] to 0 when
## changed. (Resetting the current animation)
@export var symbol: String = '':
	set(v):
		symbol = v
		symbol_changed.emit(v)
		frame = 0
		_timer = 0.0

## Keeps track of whether or not the sprite is being animated automatically.
@export var playing: bool = false

## Defines what happens when the end of the animation is reached.
## [br][br]Loop loops the animation forever and Play Once just stops.
@export_enum('Loop', 'Play Once') var loop_mode: String = 'Loop'

@export_tool_button('Cache Atlas', 'Save') var cache_atlas := _cache_atlas
@export_tool_button('Reload Atlas', 'Reload') var reload_atlas := _reload_atlas

var _timeline:
	get:
		if not is_instance_valid(_animation):
			return null
		return _animation.symbol_dictionary.get(symbol, _animation.timeline)

var _collections: Array[SpriteCollection]
var _animation: AtlasAnimation
var _timer: float = 0.0
var _current_transform: Transform2D = Transform2D.IDENTITY
var _canvas_items: Array[RID] = []
var _filters: Array[Filter] = []

signal finished
signal symbol_changed(symbol: String)
signal frame_changed(frame_int: int)

#region Custom Shit
var _added_anims:Dictionary[String, AnimData] = {}
var frame_index:int = -1
var cur_anim:StringName = '':
	set(an): if _added_anims.has(an): cur_anim = an

func add_anim_by_frames(alias:String, frames:Array = [], fps:float = 24.0, loop:bool = false):
	var new_anim := AnimData.new()
	if frames.size() == 2:
		var le_arr:Array[int] = []
		for i in range(frames[0], frames[1]):
			le_arr.append(i)
		frames = le_arr

	new_anim.frames = frames
	new_anim.framerate = fps
	new_anim.loop = loop
	print('added %s, with %s frames and %s fps' % [alias, frames.size(), fps])
	_added_anims.set(alias, new_anim)

func add_anim_by_symbol(alias:String, symb:String, frames:Array = [], fps:float = 24.0, loop:bool = false) -> void:
	var new_anim := AnimData.new()
	new_anim.anim = symb
	if frames.size() == 2:
		var le_arr:Array[int] = []
		for i in range(frames[0], frames[1]):
			le_arr.append(i)
		frames = le_arr

	new_anim.frames = frames
	new_anim.framerate = fps
	new_anim.loop = loop
	print('added %s (%s), with %s custom frames at %s fps' % [alias, symb, frames.size(), fps])
	_added_anims.set(alias, new_anim)

func get_frame_count(anim:String) -> int:
	return _added_anims[anim].frames.size() if _added_anims.has(anim) else 0

func play_anim(anim:String, force:bool = false) -> void:
	if !_added_anims.has(anim): return
	var da_anim:AnimData = _added_anims[anim]
	if !force and cur_anim == anim and \
	 frame_index < da_anim.frames.size() - 1: return #or (!da_anim.anim.is_empty() and frame < _timeline.length): return
	playing = true
	_timer = 0.0
	frame_index = 0

	if !da_anim.anim.is_empty():
		symbol = da_anim.anim

	frame = da_anim.frames[0] if !da_anim.frames.is_empty() else 0
	cur_anim = anim

func pause() -> void: playing = false
#endregion

func _process(delta: float) -> void:
	if not is_instance_valid(_animation):
		if frame > 0:
			frame = 0
		return

	if not playing:	return

	_timer += delta
	if cur_anim.is_empty():
		if _timer >= 1.0 / _animation.framerate:
			#var frame_diff := _timer / (1.0 / _animation.framerate)
			_timer -= (1.0 / _animation.framerate) #* frame_diff
			frame += 1 #floori(frame_diff)
				#_timer -= (1.0 / _animation.framerate) #* frame_diff
			if frame > _timeline.length - 1:
				match loop_mode:
					'Loop':
						frame = 0
					_:
						if playing:
							playing = false
							finished.emit()
						frame = _timeline.length - 1
	else:
		var _le_data:AnimData = _added_anims[cur_anim]
		if _timer >= 1.0 / _le_data.framerate:
			_timer = 0.0
			var symb_anim:bool = !symbol.is_empty()

			if symb_anim and _le_data.frames.is_empty() and frame < _timeline.length - 1: frame += 1
			if _le_data.frames.size() - 1 > frame_index:
				frame_index += 1
				frame = _le_data.frames[frame_index]
			else:
				if _le_data.loop:
					if _le_data.frames.size() > 0:
						frame_index = 0
						frame = _le_data.frames[0]
					else:
						frame = 0
					playing = true
					return

				playing = false
				finished.emit()
				if !_le_data.frames.is_empty():
					frame = _le_data.frames[-1]
				else:
					frame = _timeline.length - 1

func _cache_atlas() -> void:
	var parsed := ParsedAtlas.new()
	parsed.collections = _collections
	parsed.animation = _animation

	var atlas_directory := atlas
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()

	var err := ResourceSaver.save(parsed, \
			'%s/Animation.res' % [atlas_directory], ResourceSaver.FLAG_COMPRESS)

	if err != OK: printerr(err)


func _reload_atlas() -> void:
	var atlas_directory := atlas
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()
	load_atlas(atlas_directory, false)

## Loads a new atlas from the specified [param path].
func load_atlas(path: String, use_cache: bool = true) -> void:
	_collections.clear()
	_animation = null

	var atlas_directory := path
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()

	var parsed_path := '%s/Animation.res' % atlas_directory
	if ResourceLoader.exists(parsed_path) and use_cache:
		var parsed: ParsedAtlas = load(parsed_path)
		_animation = parsed.animation
		_collections = parsed.collections
		_clear_items()
		frame = 0
		return

	var files := ResourceLoader.list_directory(atlas_directory)
	for file in files:
		if file.begins_with('spritemap') and file.ends_with('.json'):
			var spritemap_string := FileAccess.get_file_as_string('%s/%s' % [atlas_directory, file])
			var spritemap_json: Variant = JSON.parse_string(spritemap_string)
			if spritemap_json == null:
				printerr('Failed to parse %s' % file)
				return
			var sprite_collection := SpriteCollection.load_from_json(
				spritemap_json,
				load('%s/%s.png' % [atlas_directory, file.get_basename()])
			)
			_collections.push_back(sprite_collection)

	var animation_string := FileAccess.get_file_as_string('%s/Animation.json' % [atlas_directory])
	if animation_string.is_empty():
		return

	var animation_json: Variant = JSON.parse_string(animation_string)
	if animation_json == null:
		return
	_animation = AtlasAnimation.load_from_json(animation_json)
	frame = 0


func _draw_symbol(element: Element) -> void:
	if not _animation.symbol_dictionary.has(element.name):
		printerr('Tried to draw invalid symbol "%s"' % [element.name])
		return

	_filters = element.filters
	_draw_timeline(_animation.symbol_dictionary.get(element.name), element.frame)


func _draw_sprite(element: Element) -> void:
	for collection in _collections:
		if not collection.map.has(element.name):
			continue
		var use_item: bool = true
		var sprite: CollectedSprite = collection.map.get(element.name)
		var item: RID
		if use_item:
			item = RenderingServer.canvas_item_create()
			_canvas_items.push_back(item)
			RenderingServer.canvas_item_set_z_index(item,
					mini(_canvas_items.size() - 1, RenderingServer.CANVAS_ITEM_Z_MAX))
			RenderingServer.canvas_item_set_parent(item, get_canvas_item())
			RenderingServer.canvas_item_set_transform(item, _current_transform)
			if material:
				RenderingServer.canvas_item_set_material(item, material.get_rid())

			#if not _filters.is_empty():
				#var filter_material: ShaderMaterial = _filter_material.duplicate()
				#RenderingServer.canvas_item_set_material(item, filter_material.get_rid())
				#
				#for filter in _filters:
					#match filter.type:
						#Filter.FilterType.BLUR:
							#filter_material.set_shader_parameter('test', 4.0)
		else:
			draw_set_transform_matrix(_current_transform)

		if is_instance_valid(sprite.custom_texture):
			if use_item:
				RenderingServer.canvas_item_add_texture_rect(
					item,
					Rect2(
						Vector2.ZERO,
						Vector2(sprite.rect.size.y, sprite.rect.size.x) \
								* (Vector2.ONE / collection.scale)
					),
					sprite.custom_texture
				)
			else:
				draw_texture_rect(
					sprite.custom_texture,
					Rect2(
						Vector2.ZERO,
						Vector2(sprite.rect.size.y, sprite.rect.size.x) \
								* (Vector2.ONE / collection.scale)
					),
					false
				)
		else:
			if use_item:
				RenderingServer.canvas_item_add_texture_rect_region(
					item,
					Rect2(Vector2.ZERO, Vector2(sprite.rect.size) * (Vector2.ONE / collection.scale)),
					collection.texture,
					Rect2(sprite.rect)
				)
			else:
				draw_texture_rect_region(
					collection.texture,
					Rect2(Vector2.ZERO, Vector2(sprite.rect.size) * (Vector2.ONE / collection.scale)),
					Rect2(sprite.rect),
				)
		return
	printerr('Tried to draw invalid sprite "%s"' % [element.name])


func _draw_timeline(timeline: Timeline, target_frame: int) -> void:
	var layer_transform := _current_transform
	for i in timeline.layers.size():
		var layer: Layer = timeline.layers[timeline.layers.size() - (i + 1)]
		for layer_frame in layer.frames:
			if target_frame < layer_frame.index:
				continue
			if target_frame > layer_frame.index + layer_frame.duration - 1:
				continue
			for element in layer_frame.elements:
				_current_transform = layer_transform
				_current_transform *= element.transform
				match element.type:
					Element.ElementType.SYMBOL:
						_draw_symbol(element)
					Element.ElementType.SPRITE:
						_draw_sprite(element)


func _clear_items() -> void:
	RenderingServer.canvas_item_clear(get_canvas_item())
	while not _canvas_items.is_empty():
		var item: RID = _canvas_items.pop_back()
		RenderingServer.free_rid(item)

func _exit_tree() -> void:
	_clear_items()

func _draw() -> void:
	_clear_items()

	if not is_instance_valid(_timeline):
		return
	_current_transform = Transform2D.IDENTITY
	_draw_timeline(_timeline, frame)

class AnimData extends Resource:
	var anim:String = ''
	var framerate:float = 24.0
	var frames:Array = []
	var loop:bool = false
