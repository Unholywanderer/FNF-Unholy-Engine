extends Node2D

var credits:Array[Array] = [
	['Main Fuckos', 'me me me i worked on this hi helelo!!!'],
	['Unholywanderer04', 'unholy', 'Main Programmer', \
		Color.REBECCA_PURPLE, func(): get_tree().quit()],
	['TheConcealedCow', 'cow', 'Artist, Created assets\n(Event Strum/Note, Notif Icons, etc.)', \
		Color('E0E0E0'), func():
			$cow.visible = true
			$cow.play()],
	['Ashley', 'puta', 'Artist, Created assets\n(Note/Hold Splashes, "Epic!!/Miss" sprites, etc.)', \
		Color.CYAN, func(): pass],

	['People I Stole From', 'i love stealing code'],
	['Shadow Mario', 'shadow', 'Used chunks of code from Psych and used some spritesheets', \
		Color.DIM_GRAY, func(): OS.shell_open('https://github.com/ShadowMario')],
	['Rudyrue', 'rudy', 'Better Conductor Sync and Note Offset PR\nmy cute and talented friend', \
		Color('75471f'), func(): OS.shell_open('https://bsky.app/profile/rudyrue.bsky.social')],
	['Zyflx', 'zyflx', 'Used their note handling and some other things', \
		Color('3DC74A'), func(): OS.shell_open('https://www.youtube.com/@Zyflx')],

	['Crowplexus', 'crow', 'Used code from their godot project and some ideas', \
		Color.DARK_RED, func(): OS.shell_open('https://github.com/crowplexus')],

	['Mae', 'mae', 'Godot ports of base fnf shaders, and some other utilities/scripts', \
		Color('FF3B3B'), func(): OS.shell_open('https://bsky.app/profile/mableyea.bsky.social')],

	['Maru', 'maru',  'Spritesheets and also code i think', \
		Color('368AC2'), func(): OS.shell_open('https://www.youtube.com/watch?v=BLqqWorGGz0')],

	['EIRTeam', 'github', 'FFmpeg video support addon',
		Color.DIM_GRAY, func(): OS.shell_open('https://github.com/EIRTeam/EIRTeam.FFmpeg')],

	['Cracsthor', 'face', 'PhantomMuff font, I\'m sure you know that',
		Color.ORANGE_RED, func(): OS.shell_open('https://gamebanana.com/tools/7763')],

	['Random Fuckheads', 'Who in the world'],
	['Daniel', 'daniel', 'who the FUCK', \
		Color('383657'), func(): Prefs.daniel = true],
	['Kelsay', 'kelsey', 'Random!!\n(icon by withbolognese)',
		Color('4A6C96'), func(): OS.shell_open('https://youtu.be/ysCO5pHe6GY')],

	['drew me fnf bfs', 'yeaha babye!!'],
	['Ashley', 'puta', 'drew a bf i think idk', \
		Color.CYAN, func(): Prefs.femboy = !Prefs.femboy],
	['Moonlight', 'moonlight', 'drew a bf i think idk', \
		Color.CYAN, func(): pass],
	['Betty', 'betty', 'madly in love with daniel', \
		Color.CYAN, func(): pass],
	['Moro', 'empty', 'something about above average weight female dogs??', \
		Color.CYAN, func(): pass],

	['this person did nothing', 'planky'],
	['plank', 'plank',  'made 4 commits', \
		Color('943DD6'), func(): OS.shell_open('https://en.wikipedia.org/wiki/Homosexuality')],

	['Funkin\' Crew', 'those people, you know them cmon'],
	['NinjaMuffin99', 'empty', 'You know him'],
	['Phantom Arcade', 'empty', 'That art guy with the animation'],
	['Kawai Sprite', 'empty', 'Music indiviudial i think'],
	['EvilSk8r', 'empty', 'holy arts above'],
	['EliteMasterEric', 'empty', 'You know him also'],
	['Like a lot more'],
]

var quotes:Dictionary = {
	'unholywanderer04': ['wee wee whaha yahoo yippee yay!!', 'i am a femboy!1!', 'guh!!!', 'balls', ':AINT_NO_WAY:'], # ill end your life with my own hands
	'shadow mario': ['WikiHow: How to handle fame'],
	'zyflx': ['i still dont know what i want my quote to be, i have no ideas', 'i  love boobies'],
	'rudyrue': ['i make things !!'],
	'crowplexus': ['Venha pequena fruta, venha comigo', 'Press [ Crow ] to crow', 'sans is at my door'],
	'maru': ['oogie boogie please call my phone number'],
	'betty': ['daniel.........:heart;', 'no me den papita frita no tengo autocontrol'],
	'ashley': ['play beatblock 🎉🎉', 'this is so peam', 'what the hell!! give me wuote ideas\nquote'],
	'theconcealedcow': ['who are you why are you in my house'],
	'mae': ['waiter!, waiter! more shaders please!!'],
	'kelsay': ['Death to Azure Temple Zone.'],
}

var heading_changes:Array = []
var cred_group:Array = []
@onready var cred_desc:Label = $CredDesc # my alphabet isnt good enough for this to work good, so
var cur_select:int = 1 # see if its on 0 it just while loops to death

func _ready():
	Discord.change_presence('Maining some Menus', 'Checkin Credits')
	$cow.animation_finished.connect(func(): $cow.visible = false)
	for i in credits:
		if i.size() != 2: continue
		heading_changes.append([credits.find(i), i])
		#credits.remove_at(credits.find(i))

	var actual_i:int = 0
	for i in credits:
		var creditee = Credit.new(i, i.size() <= 2)

		creditee.is_menu = true
		creditee.screen_offset = 450
		creditee.spacing = Vector2(100, 200)

		creditee.scroll_dir = Alphabet.Scroll.RIGHT_TO_LEFT
		creditee.alignment = Alphabet.CENTER
		add_child(creditee)
		move_child(creditee, 4)
		creditee.target_y = actual_i
		cred_group.append(creditee)
		actual_i += 1

		if creditee.is_header:
			#creditee.modulate = Color.DIM_GRAY
			continue

		var icon = Icon.new()
		icon.change_icon(creditee.icon, false, true)
		creditee.add_child(icon)
		icon.position = Vector2(creditee.width / 2.0, -(icon.texture.get_height() / 2.0))
		#icon.follow_spr = tes

	update_selection()

func _process(delta:float) -> void:
	for i in credits.size():
		var item:Credit = cred_group[i]
		var alpha:float = (1.0 if i == cur_select else 1.0 - (abs(item.target_y) / 2.0))
		#if item.is_header: alpha -= 0.15
		item.modulate.a = lerp(alpha, item.modulate.a, exp(-delta * 5))

func _unhandled_key_input(_event:InputEvent) -> void:
	if Input.is_action_just_pressed("accept"):
		cred_group[cur_select].on_press.call()
	if Input.is_action_just_pressed("back"):
		Game.switch_scene('menus/main_menu')

	if Input.is_action_just_pressed('menu_up'): update_selection(-1)
	if Input.is_action_just_pressed('menu_down'): update_selection(1)

var col_tween
func update_selection(amount:int = 0) -> void:
	if amount != 0: Audio.play_sound('scrollMenu')
	cur_select = wrapi(cur_select + amount, 1, credits.size())
	while credits[cur_select].size() <= 2:
		cur_select = wrapi(cur_select + amount, 1, credits.size())

	var cur_cred:Credit = cred_group[cur_select]

	for i in heading_changes.size():
		if cur_select >= heading_changes[i][0]:
			$Heading.text = heading_changes[i][1][0]
			$HeadingDesc.text = heading_changes[i][1][1]

	cred_desc.text = cur_cred.description
	#cred_desc.color = Color.WHITE

	$Quote.text = '"Thank You!"'
	if quotes.has(cur_cred.creditee.to_lower()):
		$Quote.text = '"'+ quotes[cur_cred.creditee.to_lower()].pick_random() +'"'

	if col_tween: col_tween.kill()
	col_tween = create_tween()
	col_tween.tween_property($BG, 'modulate', cur_cred.bg_color, 0.5)
	#col_tween.parallel()
	#col_tween.tween_property($BG2, 'modulate', cur_cred.bg_color, 0.5)

	for i in credits.size():
		var item = cred_group[i]
		item.target_y = i - cur_select
		#item.modulate.a = (1.0 if i == cur_select else 1.0 - (abs(item.target_y) / 3.0))

@warning_ignore("missing_tool")
class Credit extends Alphabet:
	var creditee:String = 'nope'
	var icon:String = 'empty'
	var description:String = ''
	var bg_color:Color = Color.WHITE
	var on_press:Callable = func(): pass

	var is_header:bool = false

	func _init(cred_info:Array = ['nope'], header:bool = false):
		creditee = cred_info[0]
		is_header = header
		var da_size:int = cred_info.size()
		if da_size > 1: description = cred_info[1]
			# fuck me
		if da_size > 1:
			if header:
				description = cred_info[1]
				super(creditee)
				return
			else:
				icon = cred_info[1]
		if da_size > 2: description = cred_info[2]
		if da_size > 3: bg_color = cred_info[3]
		if da_size > 4: on_press = cred_info[4]

		super(creditee)
