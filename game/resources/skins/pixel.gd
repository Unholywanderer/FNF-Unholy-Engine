extends Resource

var cur_skin:String = 'pixel'
var strum_skin:SpriteFrames = load('res://assets/images/ui/skins/pixel/strums.res')
var rating_skin:Texture2D = load('res://assets/images/ui/skins/pixel/ratings.png')
var num_skin:Texture2D = load('res://assets/images/ui/skins/pixel/nums.png')
var timing_skin:Texture2D = load('res://assets/images/ui/skins/pixel/timings.png')

var strum_scale:Vector2 = Vector2(6, 6)
var note_scale:Vector2 = Vector2(6, 6)
var rating_scale:Vector2 = Vector2(5, 5)
var num_scale:Vector2 = Vector2(5.5, 5.5)
var time_scale:Vector2 = Vector2(2.5, 2.5)
var mark_scale:Vector2 = Vector2(4, 4)

var note_width:float = 17.0

var has_countdown:bool = true # there are countdown images for the style
var countdown_scale:Vector2 = Vector2(6, 6)

var antialiased:bool = false
