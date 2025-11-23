extends Node2D
# for menus n shit i guess

## Scenes to not auto start music on. only called on  [code]_ready()
const EXCLUDE:PackedStringArray = ['play_scene', 'charting_scene']

var pos:float = 0.0 # in case you need the position for something or whatever
var Player := AudioStreamPlayer.new()
var playing_music:bool:
	get: return Player.stream != null

var volume:float = 1.0:
	set(vol):
		volume = vol
		Player.volume_db = linear_to_db(volume)

var sync_conductor:bool = false
var loop_music:bool = true
## Current music file being played
var music:String = "" #"freakyMenu"

## Array of currently playing sounds
var sound_list:Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(Player)
	Player.finished.connect(finished)
	if music.length() == 0 and !EXCLUDE.has(Game.scene.name.to_lower()):
		play_music('freakyMenu')

func _process(_delta) -> void:
	#AudioDeviceChecker()
	if Player.stream and Player.playing:
		pos = Player.get_playback_position() * 1000.0
		if sync_conductor: Conductor.song_pos = pos

## Set the current music track without actually playing it
func set_music(new_music:String, vol:float = 1, looped:bool = true) -> void:
	var path:String = 'assets/music/'+ new_music +'.ogg'
	if !ResourceLoader.exists('res://'+ path):
		return printerr('MUSIC PLAYER | SET MUSIC: CAN\'T FIND FILE "'+ path +'"')

	Player.stream = load('res://'+ path)
	music = new_music
	volume = vol
	loop_music = looped

## Play the stated music. If called empty, will replay current track, if one exists
func play_music(to_play:String = '', looped:bool = true, vol:float = 1.0) -> void:
	if to_play.is_empty() and Player.stream == null: # why not, fuck errors
		return printerr('MUSIC PLAYER | PLAY_MUSIC: MUSIC IS NULL')

	if !to_play.is_empty(): #and to_play != music:
		set_music(to_play, vol, looped)

	if !music.is_empty():
		pos = 0
		Player.seek(0)
		Player.play()
	#Player.stream.volume_db = linear_to_db(vol)

## Stop and clear the stream if needed
func stop_music(clear:bool = true) -> void:
	Player.stop()
	if clear:
		Player.stream = null
		music = ''

func finished() -> void:
	print('Music Finished')
	if sync_conductor: Conductor.reset_beats()
	if loop_music: play_music()
	Game.call_func('on_music_finish')

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




#AudioDevice managing stuffs - mae
#how to track audio devices tutorial working 2014
var AudioDevices = {
	"current" = null,
	"cached_list" = null
}
#signal AudioDevice_changed(device)
#godot has no signal for when u change an audio device, so this does that

#func AudioDeviceChecker() -> void:
#	var device_list = AudioServer.get_output_device_list()
#	device_list.remove_at(device_list.find("Default"))
#	if AudioDevices.cached_list != device_list:
#		var newDevice = AudioDeviceHandler(device_list)
#		if newDevice != null:
#			emit_signal("AudioDevice_changed",newDevice)
#			Alert.make_alert("device_changed").text = "New Audio Device Connected! %s" % newDevice
#		AudioDevices.cached_list = device_list.duplicate()
#	else:
#		return

#func AudioDeviceHandler(device_list):
#	if AudioDevices.cached_list != null:
#		if device_list.size() > 0:
#			for device in device_list: #handle new devices
#				if not AudioDevices.cached_list.has(device):
#					AudioDevices.current = device
#					return device
#			var device = device_list[0] #if anything just use whatevers left
#			AudioDevices.current = device
#			return device
#		else:
#			push_error("no device found at all")
#			Alert.make_alert("No Audio Device Connected!",0)
#			return null
