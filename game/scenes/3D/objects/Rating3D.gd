class_name Rating3D; extends Resource;

var skin:SkinInfo
var rating_pos:Vector3 = Vector3(610, 500, 0)
var combo_pos:Vector3 = Vector3(580, 560, 0)
var spacing:float = 43.0

static var ratings_data:Dictionary = {
	'name':       ['epic', 'sick', 'good', 'bad', 'shit', 'miss'],
	'score':      [500,       350,    200,   100,    50],
	'hit_window': [22.5,       45,     90,   135,  null],
	'color':      ['ff00ff', '68fafc', '48f048', 'fffecb', 'ff0000'],
	'penalty':    [   1,        1,      1,  0.35,  0.10], # heavily penalize lower rating's score
	'hit_mod':    [ 1.0,      1.0,   0.75,   0.5,   0.2] # 1.0, 0.9, 0.7, 0.4, 0.2
}

static func get_rating(diff:float) -> String:
	for i in ratings_data.hit_window.size() - 2:
		var win = Prefs.get(ratings_data.name[i] +'_window')
		if absf(diff) <= win:
			return ratings_data.name[i]
	return ratings_data.name[ratings_data.name.size() - 2] # miss should always be the last, so check the one before

static func get_score(rating:String) -> Array:
	var index = ratings_data.name.find(rating)
	return [ratings_data.score[index], ratings_data.hit_mod[index], ratings_data.penalty[index]]

static func get_color(rating:String) -> Color:
	return Color(ratings_data.color[ratings_data.name.find(rating)])

func make_rating(rate:String = 'sick') -> VelocitySprite3D:
	var rating = VelocitySprite3D.new()
	rating.position = rating_pos
	rating.name = rate
	rating.texture = skin.rating_skin
	rating.vframes = ratings_data.name.size()
	rating.frame = ratings_data.name.find(rate.to_lower())
	
	rating.moving = true
	rating.velocity.y = randf_range(-0.1, -1)
	rating.acceleration.y = 2
	rating.scale = Vector3(skin.rating_scale.x, skin.rating_scale.y, 1)
	rating.antialiasing = skin.antialiased
	
	return rating

func make_combo(combo) -> Array[VelocitySprite3D]:
	var loops:int = 0
	var all_nums:Array[VelocitySprite3D] = []
	for i in str(combo).split():
		var num = VelocitySprite3D.new()
		num.position = combo_pos
		num.position.x += (spacing * loops)
		num.texture = skin.num_skin
		num.hframes = 10
		num.frame = int(i)
		all_nums.append(num)
		
		num.moving = true
		num.acceleration.y = randf_range(1, 1.6)
		num.velocity.y = randf_range(-0.1, -0.2)
		num.velocity.x = randf_range(-2, 3)
		
		num.scale = Vector3(skin.num_scale.x, skin.num_scale.y, 1)
		num.antialiasing = skin.antialiased
		loops += 1

	return all_nums

func make_timing(rating:VelocitySprite3D, diff:float = 0.0) -> VelocitySprite3D:
	# early is 0, 2, 4 | late is 1, 3, 5
	var early:int = (0 if diff <= 0.0 else 1)
	var frame_diffs = {'good': 0, 'bad': 2, 'shit': 4}
	var time = VelocitySprite3D.new()
	time.texture = skin.timing_skin
	time.hframes = 2; time.vframes = 3;
	time.frame = early + frame_diffs[get_rating(diff)]
	
	var offset = (rating.texture.get_width() * skin.rating_scale.x)
	time.position = rating.position
	time.position.x += offset / 2.2 * (-1.1 if early == 0 else 1.0)
	time.copy_from(rating)
	
	time.scale = Vector3(skin.time_scale.x, skin.time_scale.y, 1)
	time.antialiasing = skin.antialiased

	return time
