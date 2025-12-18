extends Node2D

var week_names:Array[String] = []
var weeks:Array[WeekItem] = []
var cur_week:int = 0

var can_change:bool = true
var cur_diff:int = 0
var diff_str:String = ''
var characters:Array[MenuChar] = []

var precache = {}

@onready var diff_spr:Sprite2D = $Difficulty/DiffSpr
@onready var diff_txt:Label = $Difficulty/DiffTxt # used if there is no difficulty sprite
@onready var arrow_left:AnimatedSprite2D = $Difficulty/ArrowLeft
@onready var arrow_right:AnimatedSprite2D = $Difficulty/ArrowRight

func _ready():
	if !Audio.playing_music:
		Audio.play_music('freakyMenu', true, 0.7)
	Discord.change_presence('I play FNF for the plot', 'Story Mode')

	var to_add = Game.week_list

	for file in DirAccess.get_files_at('res://assets/data/weeks'):
		var file_name = file.to_lower().strip_edges()
		if to_add.has(file_name) or !file_name.ends_with('.json'): continue
		to_add.append(file_name.get_basename())

	for i in to_add.size():
		if week_names.has(to_add[i]): continue
		var week_data = JsonHandler.parse_week(to_add[i])
		if week_data.has('hideStory') and week_data.hideStory: continue

		for char in week_data.weekCharacters:
			if precache.has(char): continue
			if ResourceLoader.exists('res://assets/images/story_mode/characters/'+ char +'.res'):
				precache[char] = load('res://assets/images/story_mode/characters/'+ char +'.res')

		var diffs = week_data.difficulties if week_data.has('difficulties') else []
		var song_list:Array[String] = []
		for song in week_data.songs:
			song_list.append(song[0])
		var new_week = WeekItem.new(to_add[i], song_list, diffs)
		Util.center_obj(new_week)
		new_week.story_name = week_data.storyName if week_data.has('storyName') else 'Uhmmm'
		new_week.target_y = i

		$Weeks.add_child(new_week)
		week_names.append(new_week.week_name)
		weeks.append(new_week)

	if Game.persist.week_int > -1: cur_week = Game.persist.week_int
	if Game.persist.week_diff > -1: cur_diff = Game.persist.week_diff

	var last_week = weeks[cur_week]
	cur_diff = clampi(cur_diff, 0, last_week.diff_list.size())
	var should_load:String = last_week.diff_list[cur_diff]
	diff_spr.texture = load('res://assets/images/story_mode/difficulties/'+ should_load +'.png')

	var def = ['dad', 'bf', 'gf']
	for i in 3:
		var new_char = MenuChar.new()
		new_char.dancer = (i == 2)
		#new_char.switch(precache[def[i]])
		$CharBG.add_child(new_char)
		new_char.position = Vector2(170 + (i * 450), 200)
		characters.append(new_char)

	update_list()

	Conductor.beat_hit.connect(beat_hit)

func _unhandled_key_input(event:InputEvent) -> void:
	if event.is_action_pressed('back'):
		Game.switch_scene('menus/main_menu')
	if event.is_action_pressed('accept'):
		var week = weeks[cur_week]
		Audio.stop_music()
		Conductor.reset()
		Game.persist.song_list = week.song_list
		JsonHandler.parse_song(week.song_list[0], week.diff_list[cur_diff])
		Game.switch_scene('Play_Scene')

	if event.is_action_pressed('menu_up'): update_list(-1)
	if event.is_action_pressed('menu_down'): update_list(1)

	if can_change:
		var change:int = int(Input.get_axis(&'menu_left', &'menu_right'))
		update_diff(change)
		if change != 0:
			var arr = arrow_left if change == -1 else arrow_right
			arr.frame = 0
			arr.play(('left' if change == -1 else 'right') +"_push")

		if event.is_action_released('menu_left'): arrow_left.play("left")
		if event.is_action_released('menu_right'): arrow_right.play("right")


func beat_hit(_beat:int):
	for i in characters:
		i.dance()

var diff_twn:Tween
func update_diff(amount:int = 0):
	var da_diffs = weeks[cur_week].diff_list
	can_change = da_diffs.size() > 1
	arrow_left.modulate = Color.DIM_GRAY if !can_change else Color.WHITE
	arrow_right.modulate = Color.DIM_GRAY if !can_change else Color.WHITE

	cur_diff = wrapi(cur_diff + amount, 0, da_diffs.size())

	var def_y:int = 572
	var le_path:String = 'assets/images/story_mode/difficulties/'+ da_diffs[cur_diff] +'.png'
	var exist:bool = ResourceLoader.exists('res://'+ le_path)
	diff_spr.visible = exist
	diff_txt.visible = !exist

	if exist:
		diff_spr.texture = load('res://'+ le_path)
	else:
		def_y = 539
		diff_txt.text = da_diffs[cur_diff].to_upper()

	if diff_str != da_diffs[cur_diff]:
		var to_affect = diff_spr if exist else diff_txt

		diff_str = da_diffs[cur_diff]
		to_affect.position.y = def_y - 15

		if diff_twn: diff_twn.kill()
		diff_twn = create_tween()
		diff_twn.tween_property(to_affect, 'position:y', def_y, 0.05)


func update_list(amount:int = 0):
	if amount != 0: Audio.play_sound('scrollMenu')
	cur_week = wrapi(cur_week + amount, 0, weeks.size())
	$InfoBar/Name.text = weeks[cur_week].story_name.to_upper()

	Game.persist.week_int = cur_week
	Game.persist.week_diff = cur_diff

	for i in weeks[cur_week].character_list:
		pass

	var list:String = ''
	for i in weeks[cur_week].song_list:
		list += (i +'\n')
	$Tracks/List.text = list.strip_edges()

	for i in weeks.size():
		var wek = weeks[i]
		wek.target_y = i - cur_week
		wek.modulate.a = (1.0 if i == cur_week else 0.6)

	update_diff()

class MenuChar extends AnimatedSprite2D:
	var dancer:bool = false
	var cur:String = 'bf'

	func _init() -> void:
		animation_finished.connect(dance)

	func switch(new:SpriteFrames):
		sprite_frames = new
		dance()

	var danced:bool = false
	func dance():
		if dancer:
			play('dance'+ ('Right' if danced else 'Left'))
			danced = !danced
		else:
			play('idle')

class WeekItem extends Sprite2D:
	var week_name:String = 'week'
	var story_name:String = 'Funkin Fr Fr'

	var character_list:Array = ['dad', 'bf', 'gf']
	var song_list:Array[String] = ['Test']
	var diff_list:PackedStringArray = JsonHandler.base_diffs

	func _init(week:String, songs:Array[String] = ['Test'], diffs:Array = []):
		week_name = week.to_lower().strip_edges()
		print(week_name)
		var texture_path:String = 'res://assets/images/story_mode/weeks/'+ week_name +'.png'
		if !ResourceLoader.exists(texture_path):
			texture_path = 'res://assets/images/story_mode/weeks/missing_week.png'
		texture = load(texture_path)

		if songs.size() > 0:
			song_list = songs
		else:
			song_list = ['Bopeebo', 'Fresh', 'Dad Battle']

		if diffs.size() > 0:
			for i in diffs.size():
				diffs[i] = diffs[i].to_lower().strip_edges()
			diff_list = diffs

	var flash:bool = false
	var flash_int:int = 0
	var le_fake_fps:int = roundi((1.0 / get_process_delta_time()) / 10.0)

	var target_y:int = -1
	func _process(delta:float) -> void:
		position.y = lerpf(position.y, (target_y * 120) + 570, clamp(delta * 10.2, 0.0, 1.0))

		if flash:
			flash_int += 1
			if flash_int % le_fake_fps >= floor(le_fake_fps / 2.0):
				self_modulate = Color('33ffff')
			else:
				self_modulate = Color.WHITE
