class_name SkinInfo; extends Resource;

var cur_skin:String = 'default' # just the current skin as a string
var strum_skin:SpriteFrames = preload('res://assets/images/ui/skins/default/strums.res')
var rating_skin:Texture2D = preload('res://assets/images/ui/skins/default/ratings.png')
var num_skin:Texture2D = preload('res://assets/images/ui/skins/default/nums.png')
var timing_skin:Texture2D = preload('res://assets/images/ui/skins/default/timings.png')

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

func _init(skinny:String = '') -> void:
	if !skinny.is_empty():
		load_skin(skinny)
	
func load_skin(new_skin:String = 'default'):
	if new_skin == cur_skin: 
		print('SKIN: "'+ new_skin +'" already loaded, continuing')
		return
		
	var skin_to_check:String = 'assets/images/ui/skins/%s/' % [new_skin]
	if DirAccess.dir_exists_absolute('res://'+ skin_to_check):
		cur_skin = new_skin
		var skin_file:Resource = load('res://game/resources/skins/'+ new_skin +'.gd').new()
		for item in skin_file.get_script().get_script_property_list():
			if item.name in self:
				set(item.name, skin_file.get(item.name))
	else:
		printerr('SKIN: "'+ new_skin +'" does not exist!')
		return load_skin(cur_skin)
