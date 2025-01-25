extends Node2D

const MAX_HZ = 11025.0
const MIN_DB = 60.0
const ANIMATION_SPEED = 0.1

var timer:float = 0.0
@onready var spectrum = AudioServer.get_bus_effect_instance(1, 0)
@export var updates_per_second: float = 24.0

var parent = null
var unedited_pos:Vector2 = Vector2.ZERO
var offset:Vector2 = Vector2.ZERO:
	set(off):
		unedited_pos = position - offset
		offset = off
		position = unedited_pos + offset

func _update(): # yes i did steal code from @what-is-a-git 😊😊😊
	var prev_hz:float = 0.0
	for i in 7:
		var hz:float = float(i) * MAX_HZ / float(7)
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy := clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0.0, 1.0)
		var silly := remap(energy, 0.0, 1.0, 0.0, 5.0)
		get_node('VIZ/Bar'+ str(i)).frame = int(5.0 - silly)
		prev_hz = hz

func _process(delta):
	timer += delta
	if timer >= 1.0 / updates_per_second:
		_update()
		timer = 0.0
	
func bump(forced:bool = true):
	$Frame.play('bump')
	if forced:
		$Frame.frame = 0
