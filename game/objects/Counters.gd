class_name Counters; extends Resource;
# Class that holds those tally counters and shit
# Put here so it can be used anywhere

class ClearPercent extends Node2D:
	var width:float = 0
	var height:float = 0
	var numbers:Array = []
	var is_small:bool = false
	var num_changed:bool = false
	var cur_num:int = 0:
		set(num):
			num_changed = true
			cur_num = num

	func _init(pos:Vector2 = Vector2.ZERO, start_num:int = 0, small:bool = false) -> void:
		position = pos
		cur_num = start_num
		is_small = small

		#hmm color shader does exist i guess i should make it

		var le_sma:String = 'Text'+ ('Small' if small else '')
		var per_txt:Sprite2D = Sprite2D.new()
		per_txt.centered = false
		per_txt.texture = load('res://assets/images/results_screen/clearPercent/clearPercent%s.png' % le_sma)
		if small: per_txt.position.x = 40
		height = per_txt.texture.get_height()
		add_child(per_txt)
		num_me_harder()

	func _process(delta: float) -> void:
		if num_changed: num_me_harder()

	func flash(yes:bool = true) -> void:
		for i in numbers:
			if yes: i.modulate.v = 10
			else: create_tween().tween_property(i, 'modulate:v', 1, 0.35).set_trans(Tween.TRANS_QUAD)

	func num_me_harder() -> void:
		num_changed = false
		var split:PackedStringArray = str(cur_num).split()
		for i:int in split.size():
			var num:String = split[i]
			var index:int = i + 1
			var dig_offset:int = 1 if split.size() == 1 else -1 if split.size() == 3 else 0
			var dig_size:int = 32 if is_small else 72
			var dig_height:int = -4 if is_small else 0

			var pos = Vector2((index - 1 + dig_offset) * dig_size, (index - 1 + dig_offset) * dig_height)
			pos += Vector2((-24 if is_small else 0), (0 if is_small else 72))

			if i >= numbers.size():
				var variant:bool = index >= (2 if split.size() == 3 else 1)
				var new_num = make_num(pos, num, variant)
				add_child(new_num)
				print('added num')
			else:
				numbers[i].play('number '+ num)
				numbers[i].position = pos
				numbers[i].visible = true

		for i in range(split.size(), numbers.size()):
			numbers[i].visible = false

	func make_num(pos:Vector2, digit, variant:bool) -> AnimatedSprite2D:
		var new_num := AnimatedSprite2D.new()
		new_num.position = pos
		new_num.centered = false
		var sheet:String = 'clearPercentNumber'+ ('Small' if is_small else 'Right' if variant else 'Left')
		new_num.sprite_frames = load('res://assets/images/results_screen/clearPercent/%s.res' % sheet)
		new_num.play('number '+ str(digit))
		numbers.append(new_num)
		width += new_num.sprite_frames.get_frame_texture(new_num.animation, 0).get_width()
		return new_num

class Score extends Node2D:
	var nums:Array = []
	func _init(pos:Vector2, number:int = 100) -> void:
		var le_num:String = str(number).lpad(10, '-')
		for i in 10:
			var new_num = ScoreNum.new(pos + Vector2(65 * i, 0))
			add_child(new_num)
			new_num.final_digit = le_num[i] if le_num[i] != '-' else 10
			nums.append(new_num)
	func shuffle() -> void:
		for i:int in nums.size():
			Game.scene.get_tree().create_timer((i - 1.0) / 24.0).timeout.connect(func():
				nums[i].shuffle(i)
			)

class ScoreNum extends AnimatedSprite2D:
	const num_to_string:Array = [
		"ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "DISABLED"
	]
	var glow:bool = true
	var digit:int = -1:
		set(dig):
			digit = dig
			if dig >= 0 && animation != str(dig):
				play(str(dig) if dig < 10 else 'DISABLED')
				if glow:
					glow = false
				else:
					frame = 4

	var final_digit:int:
		set(dig):
			play('DISABLED')
			final_digit = dig

	var final_delay:float = 0.0

	func _init(pos:Vector2) -> void:
		sprite_frames = load('res://assets/images/results_screen/score-digital-numbers.res')
		centered = false
		position = pos
		play('DISABLED')

	func shuffle_tween_finish() -> void:
		#var tweenFunction = function(x) {
		#	var digitRounded = Math.floor(x);
		#	//if(digitRounded == final_digit) glow = true;
		#	digit = digitRounded;
		#};

		create_tween().tween_method(func(v): digit = floor(v), 0.0, final_digit, 23.0 / 24.0)\
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).finished.connect(func():
			get_tree().create_timer(final_delay / 24.0, false).timeout.connect(func():
				play(animation)
				frame = 0
			)
		)

	var shuffle_timer:Timer = Timer.new()
	var loops:int = 0
	func shuffle(indx:int = 0) -> void:
		if final_digit == 10: return
		var duration:float = 41.0 / 24.0
		var interval:float = 1.0 / 24.0
		if shuffle_timer.get_parent() == null: Game.scene.add_child(shuffle_timer)
		shuffle_timer.start(1.0 / 24.0)
		shuffle_timer.timeout.connect(func():
			loops += 1
			digit = wrapi(digit + randi_range(1, 4), 0, 10)
			if loops >= 50:
				shuffle_timer.stop()
				digit = final_digit
				frame = 0
				play()

			#if (shuffleTimer.loops > 0 && shuffleTimer.loopsLeft == 0)
			#{
			#//digit = finalDigit;
			#finishShuffleTween();
			#}
		)


class Tally extends Node2D:
	var nums:Array[AnimatedSprite2D] = [] # i could just iterate over the children in the node but ehh
	var cur_num:int = 0
	var actual_num:int = 0

	var color:Color = Color.WHITE:
		set(new):
			color = new
			modulate = color

	func _init(pos:Vector2 = Vector2.ZERO, true_number:int = 0, color:Color = Color.WHITE) -> void:
		position = pos
		actual_num = true_number
		print(cur_num, ' ', actual_num)
		self.color = color
		if actual_num == cur_num: num_that_shit_babe()

	func _process(delta:float) -> void:
		if cur_num != actual_num: num_that_shit_babe()

	func num_that_shit_babe():
		var split_shit:Array = str(cur_num).split()
		for i in split_shit.size():
			if i >= nums.size():
				var _x = 43 * i
				var num = make_num(int(split_shit[i]))
				num.position.x = _x
				add_child(num)
			else:
				nums[i].play(split_shit[i] +' small')

	func make_num(digit:int = 0) -> AnimatedSprite2D:
		var new_num = AnimatedSprite2D.new()
		new_num.centered = false
		new_num.sprite_frames = ResourceLoader.load('res://assets/images/results_screen/tallieNumber.res')
		new_num.play(str(digit) +' small')
		nums.append(new_num)
		return new_num
