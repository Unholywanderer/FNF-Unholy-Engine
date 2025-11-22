extends Node2D

@onready var base_songs:PackedStringArray = FileAccess.open("res://assets/songs/songs.txt", FileAccess.READ).get_as_text().split('\n')
var base_list:Array[String] = []
var song_list:Array[String] = []
var list_list:Array[Array] = []
var cur_list:int = 0
var cur_song:int = 0
var selectable_songs:Array[Label] = []
var songs = []
var can_select:bool = true

var downscroll_check:CheckBox
var hitsound_check:CheckBox
var auto_check:CheckBox
var last_windows:Array = [0, 0, 0]
var ratings = ['sick', 'good', 'bad']
func _ready():
	# song list
	if Audio.music != 'freakyMenu':
		Audio.play_music('freakyMenu')

	for bleh in base_songs:
		base_list.append(bleh.replace('\r', ''))
	#song_list.append_array(base_songs)
	#print(base_songs)
	for song in DirAccess.get_directories_at('res://assets/songs'):
		if base_list.has(song): continue
		song_list.append(song)

	list_list.append(base_list)
	list_list.append(song_list)
	load_list(base_list)

	for song in base_list:
		var alphabet = Alphabet.new()
		alphabet.bold = true
		alphabet.text = song
		alphabet.is_menu = true
		alphabet.target_y = i
		songs.append(alphabet)
		add_child(alphabet)
	update_list()
	#print(list_list)

	# pref stuff
	#var things = [$SickMS, $GoodMS, $BadMS]
	#for i in 3:
	#	things[i].value = Prefs.get_pref(ratings[i] +'_window')

	#var txt = Label.new()
	#txt.text = 'Downscroll: '
	#txt.position = Vector2(800, 150)
	#txt.modulate = Color(255, 255, 255)
	#add_child(txt)

	#downscroll_check = CheckBox.new()
	#downscroll_check.position.x = txt.position.x + 100
	#downscroll_check.position.y = txt.position.y
	#downscroll_check.modulate = Color(255, 255, 255)
	#downscroll_check.button_pressed = Prefs.get_pref('downscroll')
	#add_child(downscroll_check)
	#downscroll_check.toggle_mode = true
	#downscroll_check.toggled.connect(get_tree().current_scene.downscroll_toggled)

	#var txt2 = Label.new()
	#txt2.text = 'Hitsounds: '
	#txt2.position = Vector2(800, 170)
	#txt2.modulate = Color(255, 255, 255)
	#add_child(txt2)

	#hitsound_check = CheckBox.new()
	#hitsound_check.position.x = txt2.position.x + 100
	#hitsound_check.position.y = txt2.position.y
	#hitsound_check.modulate = Color(255, 255, 255)
	#hitsound_check.button_pressed = Prefs.get_pref('hitsounds')
	#add_child(hitsound_check)
	#hitsound_check.toggle_mode = true
	#hitsound_check.toggled.connect(get_tree().current_scene.hitsound_toggled)

	#var txt3 = Label.new()
	#txt3.text = 'Autoplay: '
	#txt3.position = Vector2(800, 190)
	#txt3.modulate = Color(255, 255, 255)
	#add_child(txt3)

	#auto_check = CheckBox.new()
	#auto_check.position.x = txt3.position.x + 100
	#auto_check.position.y = txt3.position.y
	#auto_check.modulate = Color(255, 255, 255)
	#auto_check.button_pressed = Prefs.get_pref('auto_play')
	#add_child(auto_check)
	#auto_check.toggle_mode = true
	#auto_check.toggled.connect(get_tree().current_scene.auto_toggled)

	#for pref in Prefs.preferences:
		#pref
var i:int = 0
func load_list(list:Array[String]):
	cur_song = 0
	while songs.size() > 0:
		songs[0].queue_free()
		remove_child(songs[0])
		songs.remove_at(0)
	songs.clear()

	for song in list:
		var alphabet = Alphabet.new()
		alphabet.bold = true
		alphabet.text = song.replace('-', ' ')
		alphabet.is_menu = true
		alphabet.target_y = i
		songs.append(alphabet)
		add_child(alphabet)
	#for item in selectable_songs:
	#	remove_child(item)
	#	item.queue_free()
	#selectable_songs.clear()

	#for item in list:
	#	var song_txt = Label.new()
	#	song_txt.position = Vector2(100, 50 + (15 * i))
	#	song_txt.text = item
	#	selectable_songs.append(song_txt)
	#	add_child(song_txt)
	#	if i != 0:
	#		song_txt.modulate = Color(0, 0, 0)
	#	i += 1
	#i = 0

func _process(delta):
	if Input.is_action_just_pressed('accept'):
		update_hit_windows()
		Audio.stop_music()
		Conductor.embedded_song = songs[cur_song].text
		Game.switch_scene('play_scene')

	if Input.is_action_just_pressed('menu_down'):
		update_list(1)
	if Input.is_action_just_pressed('menu_up'):
		update_list(-1)
	if Input.is_action_just_pressed('menu_left'):
		switch_list(-1)
	if Input.is_action_just_pressed('menu_right'):
		switch_list(1)

	if Input.is_action_just_pressed('back'):
		Audio.play_sound('cancelMenu')
		Game.switch_scene('menus/main_menu')


func update_list(amount:int = 0):
	cur_song = wrapi(cur_song + amount, 0, songs.size())
	if amount != 0: Audio.play_sound('scrollMenu')
	for i in songs.size():
		var item = songs[i]
		item.target_y = i - cur_song
		item.modulate.a = 1 if i == cur_song else 0.6

func switch_list(amount:int = 0):
	cur_list = wrapi(cur_list + amount, 0, list_list.size())
	var new_list = list_list[cur_list]
	load_list(new_list)
	update_list()

func downscroll_toggled(is_active):
	Prefs.set_pref('downscroll', is_active)

func hitsound_toggled(is_active):
	Prefs.set_pref('hitsounds', is_active)

func auto_toggled(is_active):
	Prefs.set_pref('auto_play', is_active)

func update_hit_windows():
	var new_win = [$SickMS.value, $GoodMS.value, $BadMS.value]
	for i in ratings.size():
		Prefs.set_pref(ratings[i] +'_window', new_win[i])
