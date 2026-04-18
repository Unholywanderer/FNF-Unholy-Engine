class_name Rating; extends Resource;

var skin:SkinInfo
var rating_pos:Vector2 = Vector2(610, 500)
var combo_pos:Vector2 = Vector2(580, 560)
var spacing:float = 43.0

var max_groups:int = 10
var groups:Array[RatingGroup] = []

static var ratings_data:Array[RatingData] = [
	#RatingData.new(['fucking_awesome_andalso_awesome_and_ummm_awesome_me_thinks',10 - jillion,55.0.5]),
	RatingData.new(['epic', 500,  Prefs.epic_window]),
	RatingData.new(['sick', 350,  Prefs.sick_window]),
	RatingData.new(['good', 200,  Prefs.good_window, 1.00, 0.75, true]),
	RatingData.new(['bad' , 100,  Prefs.bad_window , 0.35,  0.5, true]),
	RatingData.new(['shit',  50,  null, 0.10,  0.2, true]),
	RatingData.new(['miss',   0,  null]),
]

static func get_rating(diff:float = 0.0) -> String:
	var lim:int = ratings_data.size() - 2 # miss should always be the last, so check the one before
	for i:int in lim:
		if absf(diff) <= ratings_data[i].hit_window:
			return ratings_data[i].name
	return ratings_data[lim].name

static func get_index(rating:String) -> int:
	for i in ratings_data.size():
		if ratings_data[i].name == rating.to_lower(): return i
	return -1

static func get_score(rating:String) -> Array:
	var rate:RatingData = ratings_data[get_index(rating)]
	return [rate.score, rate.hit_mod, rate.penalty]

func _init() -> void:
	for i in ratings_data: # update hit windows
		var window = Prefs.get(i.name +'_window')
		i.hit_window = window if window else INF

func make_rating(rate:String = 'sick') -> VelocitySprite:
	var rating = VelocitySprite.new()
	rating.position = rating_pos
	rating.texture = skin.rating_skin
	rating.vframes = ratings_data.size()
	rating.frame = get_index(rate)

	rating.moving = true
	rating.velocity.y = randi_range(-140, -175)
	rating.acceleration.y = 550
	rating.scale = skin.rating_scale
	rating.antialiasing = skin.antialiased

	return rating

func make_combo(combo) -> Array[VelocitySprite]:
	var loops:int = 0
	var all_nums:Array[VelocitySprite] = []
	for i in str(combo).split():
		var num = VelocitySprite.new()
		num.position = combo_pos
		num.position.x += (spacing * loops)
		num.texture = skin.num_skin
		num.hframes = 10
		num.frame = int(i)
		all_nums.append(num)

		num.moving = true
		num.acceleration.y = randi_range(200, 300)
		num.velocity.y = randi_range(-140, -160)
		num.velocity.x = randf_range(-5, 5)

		num.scale = skin.num_scale
		num.antialiasing = skin.antialiased
		loops += 1

	return all_nums

func make_timing(spr:VelocitySprite, rating:String = '', is_early:bool = true) -> VelocitySprite:
	# early is 0, 2, 4 | late is 1, 3, 5
	var early:int = (0 if is_early else 1)
	var frame_diffs:Dictionary = {'good': 0, 'bad': 2, 'shit': 4}
	var time := VelocitySprite.new()
	time.texture = skin.timing_skin
	time.hframes = 2; time.vframes = 3;
	time.frame = early + frame_diffs[rating]

	var offset:float = (spr.texture.get_width() * skin.rating_scale.x)
	time.position = spr.position
	time.position.x += offset / 2.2 * (-1.1 if early == 0 else 1.0)
	time.copy_from(spr)

	time.scale = skin.time_scale
	time.antialiasing = skin.antialiased

	return time

func make_group(rating:String, combo, is_early:bool = true) -> Node2D:
	while groups.size() > max_groups:
		if is_instance_valid(groups[0]):
			groups[0].queue_free()
		groups.pop_front()

	var new_group := RatingGroup.new()

	new_group.add('rating', make_rating(rating))

	if ratings_data[get_index(rating)].show_timing:
		new_group.add('timing', make_timing(new_group.rating, rating, is_early))

	if (combo is int and combo > -1) or (combo is String and !combo.is_empty()):
		new_group.add('combo', make_combo(combo))
		if rating == 'miss':
			for i in new_group.combo: i.modulate = Color.DARK_RED

	groups.append(new_group)
	return new_group

func remove_group(group:RatingGroup) -> void:
	if group == null: return
	var index:int = groups.find(group)
	if index == -1: return group.queue_free()

	if is_instance_valid(groups[index]):
		groups[index].queue_free()
	groups.pop_at(index)

class RatingData extends Resource:
	var name:String = 'sick'
	var score:int = 350
	var hit_window:float = INF
	var hit_mod:float = 1.0
	var penalty:float = 1.0
	var show_timing:bool = false

	## Should be [name, score, hit window, penalty, hit_mod, timing]
	func _init(info:Array) -> void:
		name = info[0]
		score = info[1]
		hit_window = info[2] if info[2] else 0
		if info.size() > 3:
			penalty = info[3]
			hit_mod = info[4]
			show_timing = info[5]

class RatingGroup extends Node2D:
	signal rating_tween_finished
	signal combo_tween_finished
	var rating:VelocitySprite = null
	var timing:VelocitySprite = null
	var combo:Array[VelocitySprite] = []

	func add(type:String, item) -> void:
		set(type.to_lower(), item)
		if item is Array:
			for i in item: add_child(i)
		else: add_child(item)

	func tween_rating(speed:float, delay:float = 0) -> void:
		for i in [rating, timing]:
			if !i: continue
			Util.quick_tween(i, 'modulate:a', 0, speed).set_delay(delay)\
			 .finished.connect(rating_tween_finished.emit)

	func tween_combo(speed:float, delay:float = 0) -> void:
		for i in combo:
			Util.quick_tween(i, 'modulate:a', 0, speed).set_delay(delay)
		get_tree().create_timer(speed + delay, false).timeout.connect(combo_tween_finished.emit)
