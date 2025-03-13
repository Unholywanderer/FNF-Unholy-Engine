extends Node2D

const EFFECTS:String = '[center][wave]' # effects for the "variant" text
var songs_in_folder = DirAccess.get_directories_at('res://assets/songs')

var added_songs:Array[String] = [] # a list of all the song names, so no dupes are added
var added_weeks:Array[String] = [] # same but for week jsons

var diff_list:Array = JsonHandler.base_diffs
var diff_int:int = 1
var diff_str:String = 'normal'

# need a week json in order to use these
var variant_list:Array = []
var vari_int:int = 0
var variant_str:String = ''

var last_loaded:Dictionary = {song = '', diff = '',  variant = ''}
var cur_song:int = 0
var songs:Array[FreeplaySong] = []
var icons:Array[Icon] = []
func _ready():
	Game.persist.song_list = []
	if !Audio.playing_music:
		Audio.play_music('freakyMenu', true, 0.7)
	Discord.change_presence('Maining some Menus', 'In Freeplay')
		
	added_weeks.append_array(Game.persist.week_list) # base stuff first~
	var other_weeks = []
	for i in DirAccess.get_files_at('res://assets/data/weeks'): # then go through the weeks folder for any others
		if !i.ends_with('.json') or added_weeks.has(i): continue
		other_weeks.append(i.replace('.json', ''))

	added_weeks.append_array(other_weeks)
	
	for file in added_weeks: 
		var week_file = JsonHandler.parse_week(file)
		var d_list = week_file.difficulties if week_file.has('difficulties') else []
		if d_list is String: d_list = d_list.split(',')
		var v_list = {}
		if 'variants' in week_file:
			v_list = week_file.variants
			
		for song in week_file.songs:
			add_song(FreeplaySong.new(song, d_list, v_list))
	
	for song in songs_in_folder: # then add any other fuckass songs without a json
		add_song(FreeplaySong.new([song, 'bf', [100, 100, 100]]))
	
	if JsonHandler._SONG.has('song'):
		last_loaded.song = Game.format_str(JsonHandler._SONG.song)
		if JsonHandler.song_root != '':
			last_loaded.song = JsonHandler.song_root
			last_loaded.variant = JsonHandler.song_variant.substr(1)
		last_loaded.diff = JsonHandler.get_diff
		cur_song = added_songs.find(last_loaded.song)
		diff_int = songs[cur_song].diff_list.find(last_loaded.diff)
		if last_loaded.variant != '':
			vari_int = songs[cur_song].variants.keys().find(last_loaded.variant)
			
	
	update_list()
	
func add_song(song:FreeplaySong) -> void:
	var song_name:String = Game.format_str(song.song)
	if added_songs.has(song_name):
		#print_rich("[color=yellow]"+ song.song +"[/color] already added, skipping")
		song.queue_free()
		return
	
	added_songs.append(song_name)
	add_child(song)
	songs.append(song)

	var icon = Icon.new()
	add_child(icon)
	icon.change_icon(song.icon)
	icon.is_menu = true
	icon.follow_spr = song
	icons.append(icon)
	
	if !songs_in_folder.has(song_name):
		song.modulate = Color.RED
		icon.hframes = 1
		icon.texture = load('res://assets/images/ui/noti_cross.png')
		icon.scale = Vector2(1.1, 1.1)

var lerp_score:int = 0
var actual_score:int = 2384397

var in_time:float = 0.0
func _process(delta):
	in_time += delta
	lerp_score = floor(lerp(actual_score, lerp_score, exp(-delta * 24)))
	if abs(lerp_score - actual_score) <= 10:
		lerp_score = actual_score
		
	$SongInfo/Score.text = 'Best Score: '+ str(lerp_score)
	$SongInfo/Score.position.x = Game.screen[0] - $SongInfo/Score.size[0] - 6
	$SongInfo/ScoreBG.scale.x = Game.screen[0] - $SongInfo/Score.position.x + 6
	$SongInfo/ScoreBG.position.x = Game.screen[0] - ($SongInfo/ScoreBG.scale.x / 2)
	
	$SongInfo/Difficulty.position.x = int($SongInfo/ScoreBG.position.x + ($SongInfo/ScoreBG.size[0] / 2))
	$SongInfo/Difficulty.position.x -= ($SongInfo/Difficulty.size[0] / 2) + 150
	$SongInfo/ScoreBG.position.x -= 215

var col_tween
func update_list(amount:int = 0) -> void:
	if amount != 0: Audio.play_sound('scrollMenu')
	cur_song = wrapi(cur_song + amount, 0, songs.size())
	
	if col_tween: col_tween.kill()
	col_tween = create_tween()
	col_tween.tween_property($MenuBG, 'modulate', songs[cur_song].bg_color, 0.3)
	
	diff_list = songs[cur_song].diff_list
	variant_list = songs[cur_song].variants.keys()
	change_variant()
	change_diff()
	
	for i in songs.size():
		var item = songs[i]
		item.target_y = i - cur_song
		item.visible = !(abs(item.target_y) > 5) # no need to have everything visible if its offscreen
		icons[i].visible = item.visible          # these dont change draw calls but it can help fps
		if item.visible:
			item.modulate.a = (1.0 if i == cur_song else 0.6)

func change_diff(amount:int = 0) -> void:
	var use_list = songs[cur_song].variants[variant_str] if songs[cur_song].variants.size() > 1 else diff_list
	
	diff_int = wrapi(diff_int + amount, 0, use_list.size())
	diff_str = use_list[diff_int]
	var text = '< '+ diff_str.to_upper() +' >'
	if use_list.size() == 1: text = text.replace('<', ' ').replace('>', ' ')
	actual_score = HighScore.get_score(added_songs[cur_song], diff_str)
	$SongInfo/Difficulty.text = text

func change_variant(amount:int = 0) -> void:
	var has_variants = variant_list.size() > 1
	$SongInfo/VariantTxt.modulate = Color.WHITE if has_variants else Color.DIM_GRAY
	$SongInfo/VariantTxt/Notice.visible = has_variants
	if !has_variants:
		vari_int = 0 # just in case
	
	vari_int = wrapi(vari_int + amount, 0, variant_list.size())
	variant_str = variant_list[vari_int]
	$SongInfo/VariantTxt.text = EFFECTS + variant_str.to_upper()
	if !has_variants: $SongInfo/VariantTxt.text = $SongInfo/VariantTxt.text.replace('[wave]', '')
	change_diff()

var hold_time:float = 0.0
func _unhandled_key_input(_event):
	var shifty = Input.is_key_pressed(KEY_SHIFT)
	var diff:int = 4 if shifty else 1
	var just_pressed:Callable = func(action): return Input.is_action_just_pressed(action)
	var is_held:Callable = func(action): return Input.is_action_pressed(action) and !just_pressed.call(action)
	#var is_pressed:Callable = func(action): return just_pressed.call(action) or is_held.call(action)

	if Input.is_key_pressed(KEY_R):
		print('Erasing '+ ('all' if shifty else diff_str) +' | '+ songs[cur_song].text)
		HighScore.clear_score(songs[cur_song].text, diff_str, shifty)
		update_list()
		
	if just_pressed.call('menu_down'): update_list(diff)
	if just_pressed.call('menu_up')  : update_list(-diff)
	
	if is_held.call('menu_down') or is_held.call('menu_up'):
		hold_time += get_process_delta_time()
		if hold_time >= (1.5 * get_process_delta_time()):
			hold_time = 0
			update_list(diff * Input.get_axis('menu_up', 'menu_down'))
			
	if just_pressed.call('menu_left') : change_diff(-1)
	if just_pressed.call('menu_right'): change_diff(1)
	if Input.is_key_pressed(KEY_CTRL):
		change_variant(1)
	
	if just_pressed.call('back'):
		Audio.play_sound('cancelMenu')
		Game.switch_scene('menus/main_menu')
		
	if Input.is_key_pressed(KEY_ENTER) and in_time >= 0.15:
		Audio.stop_music()
		Conductor.reset()
		if last_loaded.song != songs[cur_song].text or last_loaded.diff != diff_str\
		  or last_loaded.variant != variant_str or shifty:
			JsonHandler.parse_song(songs[cur_song].text, diff_str, variant_str)
		JsonHandler.song_diffs = songs[cur_song].diff_list
		Game.switch_scene('Play_Scene')
	
class FreeplaySong extends Alphabet:
	var song:String = 'Tutorial'
	var diff_list:Array = JsonHandler.base_diffs
	var variants:Dictionary = {'normal': diff_list}
	var bg_color:Color = Color.WHITE
	var icon:String = 'face'

	func _init(info, diffs:Array = [], vars:Dictionary = {}):
		if diffs.size() > 0: diff_list = diffs
		if vars.size() > 0: 
			for i:String in vars.keys():
				var var_diffs:Array = vars[i]
				variants[i] = var_diffs if !var_diffs.is_empty() else diff_list
		
		self.song = info[0]
		self.icon = info[1]
		self.bg_color = Color(info[2][0] / 255.0, info[2][1] / 255.0, info[2][2] / 255.0)
		
		is_menu = true
		super(song, true)
