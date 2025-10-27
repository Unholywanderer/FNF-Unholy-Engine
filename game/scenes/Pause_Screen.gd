extends Node2D

#const OPT_MENU = preload('res://game/scenes/menus/options_menu.tscn')
var this = Game.scene
@export var option_list:PackedStringArray = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit To Menu']
var options = []
var cur_option:int = 0
var in_diff:bool = false

var diffs:PackedStringArray = JsonHandler.song_diffs
var break_text = [
	'Havin a snack break', 'Stop fucking pinging me', 'Oop I fell down the stairs',
	'Damn, I can\'t funk like this', 'Time to touch some grass', 'Shittin rn keep it down',
	'pissing and shitting', 'who up straight up "funkin" it and by "it" i mean; the friday'
]
func _ready():
	Discord.change_presence('Paused '+ this.SONG.song +' - '+ JsonHandler.get_diff.to_upper(), break_text.pick_random())
	Conductor.paused = true

	$SongName.text = JsonHandler._SONG.song
	$SongName.modulate.a = 0
	create_tween().tween_property($SongName, 'modulate:a', 1, 0.3)

	$Diff.text = JsonHandler.get_diff.to_upper()
	$Diff.modulate.a = 0
	create_tween().tween_property($Diff, 'modulate:a', 1, 0.3).set_delay(0.15)

	$Time.text = Util.to_time(max(Conductor.song_pos, 0)) +' / '+ Util.to_time(Conductor.song_length)
	$Time.modulate.a = 0
	create_tween().tween_property($Time, 'modulate:a', 1, 0.3).set_delay(0.4)

	$Balled.text = 'Blueballed: '+ str(Game.persist['deaths'])
	$Balled.modulate.a = 0
	create_tween().tween_property($Balled, 'modulate:a', 1, 0.3).set_delay(0.9)

	Audio.play_music('skins/%s/breakfast' % this.cur_skin, true, 0)

	create_tween().tween_property(Audio, 'volume', 0.7, 20).set_delay(1)

	$BG.modulate.a = 0
	var twen = create_tween()
	twen.tween_property($BG, 'modulate:a', 0.6, 0.4).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	if diffs.size() == 1: option_list.remove_at(2)
	for i in option_list.size():
		make_option(option_list[i], i)

	#options = [$Option1, $Option2, $Option3]
	change_selection()

func _process(_delta):
	if Input.is_action_just_pressed('menu_up'):
		change_selection(-1)
	if Input.is_action_just_pressed('menu_down'):
		change_selection(1)

	if Input.is_action_just_pressed('accept'):
		if in_diff:
			var choice = options[cur_option].text
			if diffs.has(choice.to_lower()):
				var path = 'res://assets/songs/'+ Util.format_str(this.SONG.song) +'/charts/'
				if ResourceLoader.exists(path + choice +'.json') or JsonHandler._SONG.notes.has(choice.to_lower()):
					JsonHandler.parse_song(this.SONG.song, choice)
					close()
					Conductor.reset()
					Game.reset_scene()
				else:
					Audio.play_sound('cancelMenu')
			else:
				in_diff = false
				toggle_diff_select(false)
		else:
			match option_list[cur_option]:
				'Resume':
					close()
					Conductor.paused = false
					get_tree().paused = false
				'Restart Song':
					close()
					LuaHandler.remove_all()
					Conductor.reset()
					Game.reset_scene()
				'Change Difficulty':
					in_diff = true
					toggle_diff_select(true)
				'Options':
					Audio.play_sound('cancelMenu')
					#var wah = OPT_MENU.instantiate()
					#wah.from_play = true
					#add_child(wah)
				'Exit To Menu':
					close()
					LuaHandler.remove_all()
					Conductor.reset()
					var back_to = 'story_mode' if Game.scene.story_mode else 'freeplay_classic'
					Game.switch_scene('menus/'+ back_to)
				_:
					Audio.play_sound('cancelMenu')

func change_selection(amount:int = 0) -> void:
	Audio.play_sound('scrollMenu')
	cur_option = wrapi(cur_option + amount, 0, options.size())
	for i in options.size():
		options[i].target_y = i - cur_option
		options[i].modulate.a = (1.0 if i == cur_option else 0.6)

func close() -> void:
	Audio.stop_music()
	queue_free()
	get_tree().paused = false

var hold_this = []
func toggle_diff_select(make_visible:bool = true):
	if diffs.size() == 1: return # this shouldnt happen
	cur_option = 0 if make_visible else 2
	Util.remove_all([options], self)

	var list_to_use:PackedStringArray = diffs if make_visible else option_list

	for i in list_to_use.size():
		make_option(list_to_use[i], i)
	if make_visible:
		make_option('Back', options.size())

	change_selection()

func make_option(text:String, t_y:int = -1):
	var option = Alphabet.new(text)
	option.is_menu = true
	option.target_y = t_y
	options.append(option)
	add_child(option)
