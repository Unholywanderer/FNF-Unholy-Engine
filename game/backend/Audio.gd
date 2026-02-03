extends Node2D
# for menus n shit i guess

var _player := AudioStreamPlayer.new()

## Scenes to not auto start music on. only called on [code]_ready()
const EXCLUDE:PackedStringArray = ['title_scene', 'play_scene', 'charting_scene']

## Current time of the music track. (In milliseconds)
var pos:float = 0.0
## If there is music that is both loaded and being played
var playing_music:bool:
	get: return _player.stream and _player.playing
	set(playing): _player.playing = playing

var volume:float = 1.0:
	set(vol):
		volume = vol
		_player.volume_db = linear_to_db(volume)

## Sync the Conductor's time to the current music track's time
var sync_conductor:bool = false
## If true, music will loop when it finishes
var loop_music:bool = true
## Current music file being played
var music:String = "" #"freakyMenu"

## Length of currect music track
var track_length:float = 0.0:
	get: return _player.stream.get_length()

## Called once, and ONLY ONCE, the music is finished playing, use this instead of
## [code]_player.finished.connect()[/code]
var on_finish:Callable = func(): pass

## Array of currently playing sounds
var sound_list:Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	_player.finished.connect(finished)
	if music.length() == 0 and !EXCLUDE.has(Game.scene.name.to_lower()):
		play_music('freakyMenu')

func _process(_delta) -> void:
	if playing_music:
		pos = _player.get_playback_position() * 1000.0
		if sync_conductor: Conductor.song_pos = pos

## Set the current music track without actually playing it
func set_music(new_music:String, vol:float = 1, looped:bool = true) -> void:
	var path:String = 'assets/music/'+ new_music +'.ogg'
	if !ResourceLoader.exists('res://'+ path):
		return printerr('MUSIC PLAYER | SET MUSIC: CAN\'T FIND FILE "'+ path +'"')

	_player.stream = load('res://'+ path)
	music = new_music
	volume = vol
	loop_music = looped

## Play the stated music. If called empty, will replay current track, if one exists
func play_music(to_play:String = '', looped:bool = true, vol:float = 1.0) -> void:
	if to_play.is_empty() and _player.stream == null: # why not, fuck errors
		return printerr('MUSIC PLAYER | PLAY_MUSIC: NO MUSIC TO PLAY')

	if !to_play.is_empty(): #and to_play != music:
		set_music(to_play, vol, looped)

	if !music.is_empty():
		pos = 0
		_player.seek(0)
		_player.play()
	#_player.stream.volume_db = linear_to_db(vol)

## Stop and clear the stream if needed
func stop_music(clear:bool = true) -> void:
	_player.stop()
	if clear:
		_player.stream = null
		music = ''

func seek(to:float) -> void:
	_player.seek(to / 1000)
	pos = to

func finished() -> void:
	print('Music Finished')
	if sync_conductor: Conductor.reset_beats()
	if loop_music: play_music()
	Game.call_func('on_music_finish')
	on_finish.call()
	on_finish = func(): pass # then clear it

## Get a sound from the sound folder, without actually playing it
func return_sound(sound:String, use_skin:bool = false) -> AutoSound:
	if use_skin and !sound.begins_with('skins/'):
		sound = 'skins/'+ Game.scene.cur_skin +'/'+ sound
	var to_return = AutoSound.new('res://assets/sounds/%s.ogg' % sound)
	add_child(to_return)
	return to_return

## Play a specified sound in the sound folder
func play_sound(sound:String, vol:float = 1.0, use_skin:bool = false, ext:String = 'ogg') -> void:
	if use_skin and !sound.begins_with('skins/'):
		sound = 'skins/'+ Game.scene.cur_skin +'/'+ sound

	var path = 'res://assets/sounds/%s.%s' % [sound, ext]
	var new_sound := AutoSound.new(path, vol)
	add_child(new_sound)
	new_sound.play()

## Stop and kill all currently playing sounds
func stop_all_sounds() -> void:
	while sound_list.size() != 0:
		sound_list[0].finish()

class AutoSound extends AudioStreamPlayer:
	func _init(sound_path:String = '', vol:float = 1) -> void:
		Audio.sound_list.append(self)
		stream = load(sound_path)
		volume_db = linear_to_db(vol)
		finished.connect(finish)

	func finish() -> void:
		Audio.sound_list.remove_at(Audio.sound_list.find(self))
		Audio.remove_child(self)
		queue_free()
