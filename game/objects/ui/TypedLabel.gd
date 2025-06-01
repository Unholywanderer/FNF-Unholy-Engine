class_name TypedLabel; extends Label;
## Funny text that can be typed like haxe no way

## Emitted when all the letters are visible
signal finished

@onready var timer:Timer = %TextTimer

## How fast the text will appear
@export var text_speed:float = 0.05
## If set, this sound will be played each time a letter is made visible
@export var text_sound:String = ''
## Should the text sound play on spaces
@export var sound_on_spaces:bool = false

@export_group('Sound Pitch Variance')
@export_range(0.01, 3, 0.01) var lowest:float = 1
@export_range(0.01, 3, 0.01) var highest:float = 1

var in_progress:bool:
	get: return !timer.is_stopped()

## Total letters shown, set to -1 to show everything
var vis_chars:int = 0:
	set(vis_int):
		visible_characters = vis_int
		vis_chars = vis_int
		if sound_on_spaces or text[vis_chars - 1] != ' ':
			var beep := Audio.return_sound(text_sound, true) #Audio.play_sound('dia_Speak', 1, true)
			beep.pitch_scale = randf_range(lowest, highest)
			beep.volume_db = linear_to_db(0.8)
			beep.play()
		if visible_characters >= get_total_character_count() or vis_int == -1:
			vis_chars = -1
			timer.stop()
			finished.emit()

func start() -> void:
	if !timer:
		printerr("Missing Timer Node! Make sure it's named 'TextTimer' and is accessible")
		timer = Timer.new()
		add_child(timer)
		return
	vis_chars = 0
	timer.start(text_speed)

func _ready() -> void:
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	timer.timeout.connect(func(): vis_chars += 1)
