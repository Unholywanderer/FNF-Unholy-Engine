extends StageBase

var light_stop:bool = false
var change_interval:int = 8
var prev_change:int = 0

var car_waiting:bool = false
var car1_interruptable:bool = true
var car2_interruptable:bool = true
var papr_interruptable:bool = true
const car_offsets = [[0, 0], [20, -15], [30, 50], [10, 60]]

func _ready() -> void:
	$Car1/Sprite.position = Vector2(1200, 818)
	$Car2/Sprite.position = Vector2(1200, 818)

	Main.cam.position = Vector2(400, 490)

func post_ready() -> void:
	if gf.cur_char.contains('gf'):
		gf_pos.x += 150 if !gf.speaker_data.is_empty() else 0
		gf.position.x = gf_pos.x

func _process(delta:float) -> void:
	$Skybox/Sprite.region_rect.position.x -= delta * 22
	$Smog/Sprite.region_rect.position.x += delta * 22

func beat_hit(beat:int) -> void:
	var can_change:bool = (beat == (prev_change + change_interval))

	if Util.rand_bool(10) && !can_change && car1_interruptable:
		if !light_stop:
			pass #drive_car($Car1/Sprite)
		else:
			pass #drive_car_lights($Car1/Sprite)

	if (Util.rand_bool(10) && !can_change && car2_interruptable && !light_stop):pass
		#drive_car_back($Cars2)

	if can_change:
		change_lights(beat)

func change_lights(b:int) -> void:
	prev_change = b
	light_stop = !light_stop

	if light_stop:
		$Traffic/Sprite.play('to_red')
		change_interval = 20
	else:
		$Traffic/Sprite.play('to_green')
		change_interval = 30

		if car_waiting:
			pass #finish_car_lights($Car1/Sprite)
