extends Node2D
# for menus n shit i guess

var exclude:Array = ['Play_Scene', 'Charting_Scene'] # scenes to not auto start music on
var Player := AudioStreamPlayer.new()
var volume:float = 1.0:
	set(vol): 
		volume = vol
		Player.volume_db = linear_to_db(volume)
		
var pos:float = 0.0 # in case you need the position for something or whatever

var sync_conductor:bool = false
var loop_music:bool = true
var music:String = "" #"freakyMenu" # current music being played
var sound_list:Array[AudioStreamPlayer] = [] # currently playing sounds

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(Player)
	Player.finished.connect(finished)
	if music.length() == 0 and !exclude.has(Game.scene.name):
		play_music('freakyMenu')

func _process(_delta):
	if Player.stream != null and Player.playing:
		pos = Player.get_playback_position() * 1000.0
		if sync_conductor: Conductor.song_pos = pos

func set_music(new_music:String, vol:float = 1, looped:bool = true): # set the music without auto playing it
	var path:String = 'assets/music/'+ new_music +'.ogg'
	if ResourceLoader.exists('res://'+ path):
		Player.stream = load('res://'+ path)
		music = new_music
		volume = vol
		loop_music = looped
	else: 
		printerr('MUSIC PLAYER | SET MUSIC: CAN\'T FIND FILE "'+ path +'"')
	
# play the stated music. if called empty, will replay current track, if there is one
func play_music(to_play:String = '', looped:bool = true, vol:float = 1.0) -> void:
	if to_play.is_empty() and Player.stream == null: # why not, fuck errors
		printerr('MUSIC PLAYER | PLAY_MUSIC: MUSIC IS NULL')
		return
	
	if !to_play.is_empty(): #and to_play != music:
		set_music(to_play, vol, looped)
	
	if !music.is_empty():
		pos = 0
		Player.seek(0)
		Player.play()
	#Player.stream.volume_db = linear_to_db(vol)
	
func stop_music(clear:bool = true) -> void: # stop and clear the stream if needed
	Player.stop()
	if clear:
		Player.stream = null
		music = ''

func finished():
	print('Music Finished')
	if sync_conductor: Conductor.reset_beats()
	if loop_music: play_music()
	Game.call_func('on_music_finish')

func return_sound(sound:String, use_skin:bool = false) -> AutoSound:
	if use_skin and !sound.begins_with('skins/'): 
		sound = 'skins/'+ Game.scene.cur_skin +'/'+ sound
	var to_return = AutoSound.new('res://assets/sounds/%s.ogg' % sound)
	add_child(to_return)
	return to_return

func play_sound(sound:String, vol:float = 1.0, use_skin:bool = false, ext:String = 'ogg') -> void:
	if use_skin and !sound.begins_with('skins/'): 
		sound = 'skins/'+ Game.scene.cur_skin +'/'+ sound

	var path = 'res://assets/sounds/%s.%s' % [sound, ext]
	var new_sound := AutoSound.new(path, vol)
	add_child(new_sound)
	new_sound.play()

func stop_all_sounds() -> void:
	while sound_list.size() != 0:
		sound_list[0].finish()

class AutoSound extends AudioStreamPlayer:
	func _init(sound_path:String = '', vol:float = 1):
		Audio.sound_list.append(self)
		stream = load(sound_path)
		volume_db = linear_to_db(vol)
		finished.connect(finish)
		
	func finish():
		Audio.sound_list.remove_at(Audio.sound_list.find(self))
		Audio.remove_child(self)
		queue_free()
