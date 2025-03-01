class_name SkinBase; extends Resource;

## Current Skin's name
@export var cur_skin:String = 'default' # just the current skin as a string
## The Strums that the skin will use. Must be a .res file
@export var strum_skin:SpriteFrames = preload('res://assets/images/ui/skins/default/strums.res')
@export var rating_skin:Texture2D = preload('res://assets/images/ui/skins/default/ratings.png')
@export var num_skin:Texture2D = preload('res://assets/images/ui/skins/default/nums.png')
@export var timing_skin:Texture2D = preload('res://assets/images/ui/skins/default/timings.png')

@export var strum_scale:Vector2 = Vector2(0.7, 0.7)
@export var note_scale:Vector2 = Vector2(0.7, 0.7)
@export var rating_scale:Vector2 = Vector2(0.7, 0.7)
@export var num_scale:Vector2 = Vector2(0.5, 0.5)
@export var time_scale:Vector2 = Vector2(0.7, 0.7)
@export var mark_scale:Vector2 = Vector2(0.4, 0.4)

@export var has_countdown:bool = true # there are countdown images for the skin
@export var countdown_scale:Vector2 = Vector2(1, 1)

@export var antialiased:bool = true
