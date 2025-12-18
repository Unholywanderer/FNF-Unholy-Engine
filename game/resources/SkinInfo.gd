class_name SkinInfo; extends Resource;

var cur_skin:String = 'default' # just the current skin as a string
var strum_skin:SpriteFrames = load('res://assets/images/ui/skins/default/strums.res')
var rating_skin:Texture2D = load('res://assets/images/ui/skins/default/ratings.png')
var num_skin:Texture2D = load('res://assets/images/ui/skins/default/nums.png')
var timing_skin:Texture2D = load('res://assets/images/ui/skins/default/timings.png')

var strum_scale:Vector2 = Vector2(0.7, 0.7)
var note_scale:Vector2 = Vector2(0.7, 0.7)
var rating_scale:Vector2 = Vector2(0.7, 0.7)
var num_scale:Vector2 = Vector2(0.5, 0.5)
var time_scale:Vector2 = Vector2(0.7, 0.7)
var mark_scale:Vector2 = Vector2(0.4, 0.4)

var cached_note_types:Dictionary = {
	'hurt': preload('res://assets/images/ui/skins/default/notes/hurt/note.res')
}

var note_width:float = 157.0

var has_countdown:bool = true # there are countdown images for the skin
var countdown_scale:Vector2 = Vector2(1, 1)

var antialiased:bool = true

func _init(to_load:String = '') -> void:
	load_skin(to_load)

	#var test = SkinBase.new()
	#var heh = load('res://game/resources/skins/pixel.gd').new()
	#for i in heh.get_script().get_script_property_list():
	#	test.set(i.name, heh.get(i.name))

	#ResourceSaver.save(test, 'res://assets/data/skins/pixel.tres')

func load_skin(new_skin:String = 'default') -> void:
	if new_skin == cur_skin or new_skin.is_empty():
		return print('SKIN: "'+ new_skin +'" already loaded, skipping')

	var skin_to_check:String = 'assets/data/skins/%s.tres' % [new_skin.strip_edges()]
	if ResourceLoader.exists('res://'+ skin_to_check):
		cur_skin = new_skin
		var new_skin_data:SkinBase = load('res://'+ skin_to_check)
		for field in get_property_list():
			if get(field.name) == null or field.name.contains('script'): continue
			if get(field.name) == new_skin_data.get(field.name): continue
			set(field.name, new_skin_data.get(field.name))
	else:
		printerr('SKIN: "'+ new_skin +'" does not exist!')
		return load_skin(cur_skin)
