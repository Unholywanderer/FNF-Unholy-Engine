extends AnimatedSprite2D

var week_num:int = 0:
	set(new_num):
		var temp = str(new_num)
		for i in $WeekType.get_child_count():
			var num = $WeekType.get_child(i)
			num.visible = temp.length() > i
			if num.visible: num.frame = _get_frame(temp[i], i)
		week_num = new_num

var is_weekend:bool:
	set(is_we):
		$WeekType.frame = int(is_we)
		for i in $WeekType.get_children():
			i.offset.x = (40 if is_we else 0)
			if i.frame == 0: i.offset += 10
	get: return bool($WeekType.frame) # for the funny

var bpm:int = 100: # theres no decimal in the sheet so fuck it for now
	set(new_bpm):
		var temp = str(new_bpm)
		for i in $BPM.get_child_count():
			var num = $BPM.get_child(i)
			num.visible = temp.length() > i
			if num.visible:
				num.frame = _get_frame(temp[i], i)
				num.offset.x = (5 if num.frame == 0 else 0)
		bpm = new_bpm

var difficulty:int = 10:
	set(new_diff):
		var temp = str(new_diff).lpad(2, '0')
		for i in $Diff.get_child_count():
			var num = $Diff.get_child(i)
			num.frame = _get_frame(temp[i], i)
			num.offset.x = (10 if num.frame == 0 else 0)

		difficulty = new_diff

var icon:String = 'bf':
	set(peep):
		$CharIcon.change_icon(peep)
		$CharIcon.scale += Vector2(1, 1)
	get: return $CharIcon.image

var switch_dir:bool = false
var should_scroll:bool: # should be too many letters, so scroll to show the rest
	get: return _song_txt.get_total_character_count() >= 18

@onready var _song_txt:Label = $NameBox/Song
func _ready() -> void:
	icon = 'bf'
	bpm = 100
	difficulty = 10
	week_num = 0

func _process(delta:float) -> void:
	if should_scroll:
		_song_txt.position.x -= (100 * delta) #TODO change this later
		if _song_txt.position.x < -(_song_txt.size.x):
			_song_txt.position.x = $NameBox.size.x

func _unhandled_input(_event:InputEvent) -> void:
	if Input.is_key_pressed(KEY_W):
		difficulty += 1
	if Input.is_key_pressed(KEY_S):
		difficulty -= 1

func _get_frame(num:String, _index:int) -> int:
	var frame_int:int = int(num) - 1
	if num == '0': frame_int = 9 # 0 is the last frame fuck ill change that later
	return frame_int

class Badge extends Node2D:
	var rank:String = ''
	var sprite:AnimatedSprite2D
	var blur:AnimatedSprite2D

	func _init() -> void:
		scale = Vector2(0.9, 0.9)

		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = load('res://assets/images/freeplay/rankbadges.res')
		sprite.centered = false
		add_child(sprite)

		blur = sprite.duplicate(true)
		var shad = ShaderMaterial.new()
		shad.shader = load('res://game/resources/shaders/gaussian_blur.gdshader')
		blur.material = shad
		add_child(blur)

		var shit = CanvasItemMaterial.new()
		shit.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = shit

	func change_rank(new_rank:String) -> void:
		rank = new_rank
		match new_rank.to_upper():
			'GOOD', 'GREAT': sprite.offset.y = -8
			#_: hide()
	func play_anim(n:String, force:bool) -> void:
		for i in [sprite, blur]:
			i.play(n)
			if force: i.frame = 0
