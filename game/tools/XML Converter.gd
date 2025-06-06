# By: Leather128 | Shoutouts to @swordcube and @voiddev
extends Panel

# VARIABLES #
@onready var sprite_data = $"../SpriteData"
@onready var fps_box = $FPS

var path :String = "res://Assets/Images/Characters/bf/assets"
var fps :int = 24
var looped :bool = false
var optimized :bool = true

func convert_xml() -> void:
	if path != "":
		var path_string :String

		if path.ends_with(".png") or path.ends_with(".xml"):
			path_string = path.left(len(path) - 4)
		else:
			path_string = path

		var texture = load(path_string+".png")

		if texture != null:
			var frames = SpriteFrames.new()
			frames.remove_animation("default")

			var xml = XMLParser.new()
			xml.open(path_string+".xml")

			sprite_data.frames = frames

			var previous_texture :AtlasTexture
			var previous_coords :Rect2

			while xml.read() == OK:
				if xml.get_node_type() != XMLParser.NODE_TEXT:
					var node_name = xml.get_node_name()

					if node_name.to_lower() == "subtexture":
						var frame_data :AtlasTexture

						var animation_name = xml.get_named_attribute_value("name")
						animation_name = animation_name.left(len(animation_name) - 4)

						var frame_rect = Rect2(
							Vector2(
								xml.get_named_attribute_value("x").to_float(),
								xml.get_named_attribute_value("y").to_float()
							),
							Vector2(
								xml.get_named_attribute_value("width").to_float(),
								xml.get_named_attribute_value("height").to_float()
							)
						)

						if optimized and previous_coords == frame_rect:
							frame_data = previous_texture
						else:
							var margin :Rect2

							if xml.has_attribute("frameX"):
								var frame_size_data = Vector2(
									xml.get_named_attribute_value("frameWidth").to_float(),
									xml.get_named_attribute_value("frameHeight").to_float()
								)

								if frame_size_data == Vector2(0,0):
									frame_size_data = frame_rect.size

								margin = Rect2(
									Vector2(
										-xml.get_named_attribute_value("frameX").to_float(),
										-xml.get_named_attribute_value("frameY").to_float()
									),
									Vector2(
										xml.get_named_attribute_value("frameWidth").to_float() - frame_rect.size.x,
										xml.get_named_attribute_value("frameHeight").to_float() - frame_rect.size.y
									)
								)

								if margin.size.x < abs(margin.position.x):
									margin.size.x = abs(margin.position.x)
								if margin.size.y < abs(margin.position.y):
									margin.size.y = abs(margin.position.y)

							frame_data = AtlasTexture.new()
							frame_data.atlas = texture
							frame_data.region = frame_rect

							if xml.has_attribute("frameX"):
								frame_data.margin = margin

							frame_data.filter_clip = true

						if optimized:
							previous_texture = frame_data
							previous_coords = frame_rect

						if not frames.has_animation(animation_name):
							frames.add_animation(animation_name)
							frames.set_animation_loop(animation_name, looped)
							frames.set_animation_speed(animation_name, fps)

						frames.add_frame(animation_name, frame_data)

			ResourceSaver.save(frames, path_string+".res", ResourceSaver.FLAG_COMPRESS)

			for anim in frames.animations:
				sprite_data.play(anim.name)
				await get_tree().create_timer((1.0 / frames.get_animation_speed(anim.name)) * frames.get_frame_count(anim.name)).timeout
		else:
			print(path_string+" loading failed.")

func _ready() -> void:
	Prefs.auto_pause = false
	Game.set_mouse_visibility(true)
	Audio.play_music('artisticExpression')

func _process(_delta :float) -> void:
	if Input.is_action_just_pressed("back") and not fps_box.has_focus():
		Game.switch_scene("menus/main_menu")
		Prefs.auto_pause = true

# funny signal shits
func set_path(new_path :String) -> void:
	path = new_path
	print(new_path)

func set_fps(new_fps :String) -> void:
	fps = new_fps.to_int()

func set_looped(new_looped :bool) -> void:
	looped = new_looped

func set_optimized(new_optimized :bool) -> void:
	optimized = new_optimized
