class_name SkinBase; extends Resource;

## Current Skin's name
@export var cur_skin:String = 'default' # just the current skin as a string
## The Strums that the skin will use. Must be a .res file
@export var strum_skin:SpriteFrames = load('res://assets/images/ui/skins/default/strums.res')
## Rating texture, is grid based
@export var rating_skin:Texture2D = load('res://assets/images/ui/skins/default/ratings.png')
## Combo nums texture, is grid based
@export var num_skin:Texture2D = load('res://assets/images/ui/skins/default/nums.png')
## Timing notice texture, grid based
@export var timing_skin:Texture2D = load('res://assets/images/ui/skins/default/timings.png')

## Scale the strums will take when using this skin
@export var strum_scale:Vector2 = Vector2(0.7, 0.7)
## Scale the notes sprites will take when using this skin
@export var note_scale:Vector2 = Vector2(0.7, 0.7)
## Scale the ratings will take when using this skin
@export var rating_scale:Vector2 = Vector2(0.7, 0.7)
## Scale the combo numbers will take when using this skin
@export var num_scale:Vector2 = Vector2(0.5, 0.5)
## Scale the timing sprites will take when using this skin
@export var time_scale:Vector2 = Vector2(0.7, 0.7)
## Scale the autoplay icon will take when using this skin
@export var mark_scale:Vector2 = Vector2(0.4, 0.4)

## If the skin has it's own countdown sprites and sounds
@export var has_countdown:bool = true # there are countdown images for the skin
## Scale the countdown sprites will take when using this skin
@export var countdown_scale:Vector2 = Vector2(1, 1)

## If the skin needs anti-aliasing, for your pixel sprite needs
@export var antialiased:bool = true
