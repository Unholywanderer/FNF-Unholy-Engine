extends Node2D

@onready var base_songs:PackedStringArray = FileAccess.open("res://assets/songs/songs.txt", FileAccess.READ).get_as_text().split('\n')
var base_list:Array[String] = []
var song_list:Array[String] = []
var list_list:Array[Array] = []
var cur_list:int = 0
var cur_song:int = 0

var songs = []
var icons = []
func _ready():
	if GlobalMusic.Player.stream == null:
		GlobalMusic.set_music('freakyMenu')
		
	for bleh in base_songs: 
		base_list.append(bleh.replace('\r', ''))

	for song in DirAccess.get_directories_at('res://assets/songs'):
		if base_list.has(song): continue
		song_list.append(song)

	list_list.append(base_list)
	list_list.append(song_list)
	load_list(base_list)
	update_list()
	
var i:int = 0
func load_list(list:Array[String]):
	cur_song = 0
	while songs.size() > 0:
		songs[0].queue_free()
		remove_child(songs[0])
		songs.remove_at(0)
		
		icons[0].queue_free()
		remove_child(icons[0])
		icons.remove_at(0)
	songs.clear()
	icons.clear()
	for song in list:
		var alphabet = Alphabet.new()
		alphabet.bold = true
		alphabet.text = song#.replace('-', ' ')
		alphabet.is_menu = true
		alphabet.target_y = i
		songs.append(alphabet)
		add_child(alphabet)
		
		var icon = Icon.new()
		add_child(icon)
		icon.change_icon('bf')
		icon.is_menu = true
		icon.follow_spr = alphabet
		icons.append(icon)

var lerp_score:int = 0
var actual_score:int = 2384397
func _process(delta):
	lerp_score = lerp(actual_score, lerp_score, exp(-delta * 24))
	$SongInfo/Score.text = 'Personal Best: ' + str(lerp_score)
	$SongInfo/Score.position.x = Game.screen[0] - $SongInfo/Score.size[0] - 6
	$SongInfo/ScoreBG.scale.x = Game.screen[0] - $SongInfo/Score.position.x + 6
	$SongInfo/ScoreBG.position.x = Game.screen[0] - ($SongInfo/ScoreBG.scale.x / 2)
	
	$SongInfo/Difficulty.position.x = int($SongInfo/ScoreBG.position.x + ($SongInfo/ScoreBG.size[0] / 2))
	$SongInfo/Difficulty.position.x -= ($SongInfo/Difficulty.size[0] / 2) + 150
	$SongInfo/ScoreBG.position.x -= 215
	
	if Input.is_action_just_pressed('Accept'):
		GlobalMusic.stop()
		Conductor.embedded_song = songs[cur_song].text
		Game.switch_scene('play_scene')

	if Input.is_action_just_pressed('ui_down'):
		update_list(1)
	if Input.is_action_just_pressed('ui_up'):
		update_list(-1)
	if Input.is_action_just_pressed('ui_left'):
		switch_list(-1)
	if Input.is_action_just_pressed('ui_right'):
		switch_list(1)
	
	if Input.is_action_just_pressed('ui_cancel'):
		GlobalMusic.play_sound('cancelMenu')
		Game.switch_scene('menus/main_menu')
		

func update_list(amount:int = 0):
	cur_song = wrapi(cur_song + amount, 0, songs.size())
	if amount != 0: GlobalMusic.play_sound('scrollMenu')
	for i in songs.size():
		var item = songs[i]
		item.target_y = i - cur_song
		item.modulate.a = 1 if i == cur_song else 0.6

func switch_list(amount:int = 0):
	cur_list = wrapi(cur_list + amount, 0, list_list.size())
	var new_list = list_list[cur_list]
	load_list(new_list)
	update_list()