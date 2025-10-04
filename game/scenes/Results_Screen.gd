extends Node2D

var from_story:bool = false
var score_data:ScoreData = Game.persist.scoring if Game.persist.scoring else ScoreData.new()
var rank:String = score_data.rank
var player:String = 'bf'

enum {
	PERFECT_GOLD,
	PERFECT,
	EXCELLENT,
	GREAT,
	GOOD,
	LOSS
}

@onready var diff:Sprite2D = $Difficulty
var score_counter:Counters.Score
var move_song_stuff:bool = false
var song_name
var small_counter
func _ready() -> void:
	Audio.stop_music()
	create_tween().tween_property($TopBar, 'position:y', 0, 7.0 / 24.0).set_ease(Tween.EASE_OUT)\
	  .set_trans(Tween.TRANS_QUART).set_delay(3.0 / 24.0)

	# set signals shit
	$Highscore.animation_finished.connect(func(): $Highscore.play('loop'))

	var player_data := JsonHandler.parse('data/players/'+ player +'.json')
	var item_list:Array = player_data.results[rank]

	var items = []
	for i in item_list.size():
		var item = item_list[i]
		var new_item:Node2D
		match item.renderType:
			'animateatlas':
				new_item = AnimateSymbol.new()
				new_item.atlas = 'res://assets/images/'+ item.assetPath
				new_item.frame = 0
				new_item.playing = false
				new_item.loop_frame = item.loopFrame
			_:
				new_item = AnimatedSprite2D.new()
				new_item.centered = false
				new_item.sprite_frames = load('res://assets/images/'+ item.assetPath +'.res')
				new_item.animation_finished.connect(func():
					new_item.frame = item.loopFrame
					new_item.play()
			)
		items.append(new_item)
		new_item.visible = false
		new_item.position = Vector2(item.offsets[0], item.offsets[1])
		$CharGroup.add_child(new_item)

	for i in [$SoundSystem, $RatingsPopin, $Score, $Results]: i.visible = false
	var lol = func(th):
		th.visible = true
		th.frame = 0
		th.play()

	get_tree().create_timer(6.0 / 24.0, false).timeout.connect(func(): lol.call($Results))
	get_tree().create_timer(8.0 / 24.0, false).timeout.connect(func(): lol.call($SoundSystem))
	get_tree().create_timer(21.0 / 24.0, false).timeout.connect(func(): lol.call($RatingsPopin))
	get_tree().create_timer(36.0 / 24.0, false).timeout.connect(func(): lol.call($Score))
	get_tree().create_timer(37.0 / 24.0, false).timeout.connect(start_tally)

	var tex = load('res://assets/images/results_screen/diff_'+ JsonHandler.get_diff +'.png')
	if tex == null: tex = load('res://assets/images/results_screen/diff_normal.png')
	$Difficulty.texture = tex

	var l = Vector2(Game.screen[0] / 2.0 + 300, Game.screen[1] / 2.0 - 100)
	small_counter = Counters.ClearPercent.new(l, 0, true)
	add_child(small_counter)
	small_counter.visible = false
	small_counter.z_index = -1

	song_name = FunkyTxt.new(score_data.song_name, Vector2(400, 353))
	song_name.rotation = deg_to_rad(-4.4)
	song_name.z_index = -1
	add_child(song_name)
	speed.x = -1.0 * cos(-4.4 * PI / 180.0)
	speed.y = -1.0 * sin(-4.4 * PI / 180.0)

	timer_and_song(1.0, false)

	var y_pos:int = 50

	var total = Counters.Tally.new(Vector2(350, y_pos * 3), score_data.total_notes)
	$RatingCounters.add_child(total)

	var max_c = Counters.Tally.new(Vector2(350, y_pos * 4), score_data.max_combo)
	$RatingCounters.add_child(max_c)

	y_pos += 4
	var y_off:float = 7.0

	var sicks = Counters.Tally.new(Vector2(230, (y_pos * 5) + y_off), score_data.hits.epic + score_data.hits.sick, Color("89E59E"))
	$RatingCounters.add_child(sicks)

	var goods = Counters.Tally.new(Vector2(210, (y_pos * 6) + y_off), score_data.hits.good, Color("89C9E5"))
	$RatingCounters.add_child(goods)

	var bads = Counters.Tally.new(Vector2(190, (y_pos * 7) + y_off), score_data.hits.bad, Color("E6CF8A"))
	$RatingCounters.add_child(bads)

	var shits = Counters.Tally.new(Vector2(220, (y_pos * 8) + y_off), score_data.hits.shit, Color("E68C8A"))
	$RatingCounters.add_child(shits)

	var missed = Counters.Tally.new(Vector2(260, (y_pos * 9) + y_off), score_data.hits.miss, Color("C68AE6"))
	$RatingCounters.add_child(missed)

	score_counter = Counters.Score.new(Vector2(80, 610), score_data.score)
	add_child(score_counter)
	score_counter.hide()

	for i in $RatingCounters.get_child_count():
		var rate = $RatingCounters.get_child(i)
		rate.visible = false
		get_tree().create_timer((0.3 * i) + 1.20, false).timeout.connect(func():
			rate.visible = true
			create_tween().tween_property(rate, 'cur_num', rate.actual_num, 0.5).set_trans(Tween.TRANS_QUART)\
			 .set_ease(Tween.EASE_OUT).finished.connect(func():
				rate.cur_num = rate.actual_num
				rate.num_that_shit_babe() # force update it so it deplays the proper number
			)
		)

	var delays = get_delays()
	get_tree().create_timer(delays.bf, false).timeout.connect(func():
		show_small_counter()
		for i in item_list.size():
			var item = item_list[i]
			get_tree().create_timer((item.delay if item.has('delay') else 0), false).timeout.connect(func():
				if !items[i]: return
				items[i].visible = true
				if items[i] is AnimateSymbol:
					items[i].playing = true
				else:
					items[i].play()
			)
	)

	get_tree().create_timer(delays.score, false).timeout.connect(func():
		if score_data.is_highscore:
			$Highscore.visible = true
			$Highscore.play('new')
	)

	get_tree().create_timer(delays.flash, false).timeout.connect(display_rank_shit)

	var le_song = player_data.results.music[rank.to_upper()]
	var has_intro:bool = ResourceLoader.exists('res://assets/music/results/'+ player +'/'+ le_song +'-intro.ogg')
	if has_intro:
		le_song += '-intro'

	get_tree().create_timer(delays.music, false).timeout.connect(func():
		Audio.play_music('results/'+ player +'/'+ le_song, !has_intro)

		Audio.Player.finished.connect(func():
			if Audio.music.ends_with('-intro'):
				Audio.play_music(Audio.music.replace('-intro', ''))
		)
	)

func _exit_tree() -> void:
	Audio.play_music('freakyMenu', true, 0.7)
	Game.persist.scoring = null

var speed:Vector2 = Vector2(1, 1)
func _process(delta:float) -> void:
	if move_song_stuff:
		for i in [song_name, diff, small_counter]:
			i.position.x += ((speed.x * 100) * delta)
			i.position.y += ((speed.y * 100) * delta)
	if song_name.position.x + song_name.width < 100:
		timer_and_song()

func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed('accept'):
		Game.switch_scene('menus/'+ ('story_menu' if from_story else 'freeplay_classic'))

var percent_target:int = 100
var percent_lerp:int
func start_tally() -> void:
	score_counter.show()
	score_counter.shuffle()
	$Flash.color.a = 1
	create_tween().tween_property($Flash, "color:a", 0, 5.0 / 24.0)

	var cur_percent:float = score_data.get_hit_percent()
	percent_target = floori(cur_percent)
	percent_lerp = int(max(0, percent_target - 36))

	small_counter.cur_num = percent_target
	var pos = Vector2(Game.screen[0] / 2.0 + 190, Game.screen[1] / 2.0 - 70)
	var clear_counter := Counters.ClearPercent.new(pos, percent_lerp)
	clear_counter.z_index = $CharGroup.z_index - 1
	add_child(clear_counter)

	var tween = create_tween()
	tween.tween_method(func(val):
		percent_lerp = round(percent_lerp)
		clear_counter.cur_num = roundi(val)

		if percent_lerp != clear_counter.cur_num:
			percent_lerp = clear_counter.cur_num
			Audio.play_sound('scrollMenu')
	, 0, percent_target, 58.0 / 24.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		# play confirm sound and make sure lerp didnt fuck up
		Audio.play_sound('confirmMenu')
		clear_counter.cur_num = percent_target

		clear_counter.flash()
		get_tree().create_timer(0.4, false).timeout.connect(func(): clear_counter.flash(false))

		get_tree().create_timer(0.25, false).timeout.connect(func():
			create_tween().tween_property(clear_counter, 'modulate:a', 0, 0.5).set_delay(0.5)\
			 .set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).finished.connect(clear_counter.queue_free)
		)
	)

func show_small_counter() -> void:
	small_counter.visible = true
	small_counter.flash()
	get_tree().create_timer(0.4, false).timeout.connect(func(): small_counter.flash(false))
	get_tree().create_timer(2.5, false).timeout.connect(func(): move_song_stuff = true)

func timer_and_song(timer_len:float = 3.0, auto_scroll:bool = true) -> void:
	move_song_stuff = false

	diff.position.x = 555

	var diff_y:float = 122.0

	diff.position.y = -diff.texture.get_height()
	Util.quick_tween(diff, 'position:y', diff_y, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT).set_delay(0.8)

	if small_counter:
		small_counter.position.x = (diff.position.x + diff.texture.get_width()) + 60
		small_counter.position.y = -small_counter.height
		create_tween().tween_property(small_counter, 'position:y', 122 - 6, 0.5)\
		 .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_delay(0.85)

	song_name.position.y = -song_name.height
	var ass:float = 10 * (song_name.text.length() / 15.0)
	Util.quick_tween(song_name, 'position:y', diff_y - 10 - ass, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT).set_delay(0.9)
	song_name.position.x = small_counter.position.x + 80

	get_tree().create_timer(timer_len, false).timeout.connect(func():
		var temp_speed:Vector2 = speed
		speed = Vector2.ZERO
		Util.quick_tween(self, 'speed', temp_speed, 0.7, Tween.TRANS_QUAD, Tween.EASE_IN)

		move_song_stuff = auto_scroll
	)


func display_rank_shit() -> void:
	$Flash.color.a = 1
	create_tween().tween_property($Flash, "color:a", 0, 14.0 / 24.0)

	var txt_pth = 'res://assets/images/results_screen/rankText/'

	var sc = [ShaderMaterial.new(), ShaderMaterial.new()]
	sc[0].shader = load("res://game/resources/shaders/scroll.gdshader")
	sc[0].set_shader_parameter('speed_scale', 0.01)
	sc[0].set_shader_parameter('direction', Vector2(-1, 0))

	sc[1].shader = load("res://game/resources/shaders/scroll.gdshader")
	sc[1].set_shader_parameter('speed_scale', 0.01)
	sc[1].set_shader_parameter('direction', Vector2(1, 0))
	for i in 12:
		var new_text = Sprite2D.new()
		new_text.centered = false
		new_text.texture = load(txt_pth +'rankScroll'+ rank.to_upper() +'.png')
		new_text.region_enabled = true
		new_text.position = Vector2(Game.screen[0] / 2.0 - 700, 75 + (135 * i / 2.0) + 10)
		new_text.region_rect = Rect2(0, 0, Game.screen[0] + 200, new_text.texture.get_height()) #Game.screen[0] / 2.0 - 320
		new_text.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		new_text.material = sc[int(i % 2 == 0)]
		$TxtGroup.add_child(new_text)

	$SideText.position.x = Game.screen[0] - 44
	$SideText.texture = load(txt_pth +'rankText'+ rank.to_upper() +'.png')
	$SideText.material.set_shader_parameter('speed_scale', 0)
	get_tree().create_timer(30.0 / 24.0).timeout.connect(func():
		$SideText.material.set_shader_parameter('speed_scale', 0.05)
	)

	#$BG.texture.gradient.colors[0] = Color.REBECCA_PURPLE
	#$BG.texture.gradient.colors[1] = Color.MIDNIGHT_BLUE
#func tween

func get_delays() -> Dictionary:
	var delays:Dictionary = {'music': 3.5, 'bf': 3.5, 'flash': 3.5, 'score': 3.5}
	match rank:
		'perfect_gold', 'perfect':
			delays.music = 95.0 / 24.0
			delays.bf = 95.0 / 24.0
			delays.flash = 129.0 / 24.0
			delays.score = 140.0 / 24.0
		'excellent':
			delays.music = 0.0
			delays.bf = 97.0 / 24.0
			delays.flash = 122.0 / 24.0
			delays.score = 140.0 / 24.0
		'great':
			delays.music = 5.0 / 24.0
			delays.bf = 95.0 / 24.0
			delays.flash = 109.0 / 24.0
			delays.score = 129.0 / 24.0
		'good':
			delays.music = 3.0 / 24.0
			delays.bf = 95.0 / 24.0
			delays.flash = 107.0 / 24.0
			delays.score = 127.0 / 24.0
		'loss':
			delays.music = 2.0 / 24.0
			delays.bf = 95.0 / 24.0
			delays.flash = 186.0 / 24.0
			delays.score = 207.0 / 24.0

	return delays

func getFreeplayRankIconAsset() -> String:
	match rank:
		'perfect_gold': return 'PERFECTSICK'
		'perfect'     : return 'PERFECT'
		'excellent'   : return 'EXCELLENT'
		'great'       : return 'GREAT'
		'good'        : return 'GOOD'
		_             : return 'LOSS'

class FunkyTxt extends Control:
	var width:float:
		get: return size.x
	var height:float:
		get: return size.y
	var spacing:float = -15
	var text:String = '':
		set(new):
			text = new
			for i in get_children():
				remove_child(i)
				i.queue_free()
			make_letters()

	func _init(txt:String = 'Test', pos:Vector2 = Vector2.ZERO) -> void:
		position = pos
		if !txt.is_empty():
			text = txt

	func make_letters() -> void:
		size = Vector2(0, 62)
		var res_file:SpriteFrames = load('res://assets/images/results_screen/tardling.res')
		var loops:int = 0
		for i in text.split():
			if res_file.has_animation(i):
				var new_letter = AnimatedSprite2D.new()
				new_letter.centered = false
				new_letter.position.x += (49 + spacing) * loops
				new_letter.sprite_frames = res_file
				new_letter.play(i)
				add_child(new_letter)
			size.x += 49 + spacing
			if res_file.has_animation(i) or i == ' ' or i == '-': loops += 1
