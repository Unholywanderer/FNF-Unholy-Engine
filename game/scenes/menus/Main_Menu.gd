extends Node2D

@onready var menu_sprites = [$StoryMode, $Freeplay, $Donate, $Options, $Credits]
var scene_to_load = ['story_mode', 'freeplay', 'donate', 'options_menu', 'credits']
var cur_option:int = 0

func _ready():
	Discord.change_presence('Maining some Menus', 'In the Mainest Menu')
	Audio.volume = 0.7
	for i in menu_sprites.size():
		Game.center_obj(menu_sprites[i])
		menu_sprites[i].position.y = (88 + (135 * i))
	
	$Cam.position.y = $MenuBG/Sprite2D.position.y - 3 #menu_sprites[ceil(menu_sprites.size() / 2)].position.y - 3
		
	change_selection()

func _unhandled_input(event:InputEvent) -> void:
	if Input.is_action_just_pressed('menu_down'):
		change_selection(1)
	elif Input.is_action_just_pressed('menu_up'):
		change_selection(-1)
	if Input.is_action_just_pressed('accept'):
		if scene_to_load[cur_option] != null:
			Audio.play_sound('confirmMenu')
			if scene_to_load[cur_option] != 'donate':
				Game.switch_scene('menus/'+ scene_to_load[cur_option])
			else: OS.shell_open('https://ninja-muffin24.itch.io/funkin')
		else:
			Audio.play_sound('cancelMenu')
	if Input.is_action_just_pressed('back'):
		Audio.play_sound('cancelMenu')
		Game.switch_scene('menus/title_scene')
	
	if Input.is_action_just_pressed('debug_1'):
		Game.switch_scene('debug/Character_Offsetter')
	
func change_selection(by:int = 0) -> void:
	if by != 0: Audio.play_sound('scrollMenu')
	cur_option = wrapi(cur_option + by, 0, menu_sprites.size())
	menu_sprites[cur_option].play('selected')
	
	for i in menu_sprites.size():
		if i == cur_option: continue
		menu_sprites[i].play('normal')
