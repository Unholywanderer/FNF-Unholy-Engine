extends Node2D

var initalized:bool = false
var can_rpc:bool = true
var _info = [
	{id = 1225971084998737952, l_img = 'deedee_phantonm', l_txt = 'out here unholy-ing baby'},
	{id = 1227081103932657664, l_img = 'daniel', l_txt = 'I LOVE DANIEL'}
	#'false': {id = 1225971084998737952, l_img = 'deedee_phantonm', l_txt = 'out here unholy-ing baby'}
]

var last_presence:Array[String] = ['Nutthin', 'Check it'] # hold the actual presence text, so it can swap
func init_discord() -> void:
	if initalized: return
	print('Initializing Discord...')

	DiscordRPC.app_id = _info[int(Prefs.daniel)].id
	DiscordRPC.large_image = _info[int(Prefs.daniel)].l_img
	DiscordRPC.large_image_text = _info[int(Prefs.daniel)].l_txt
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())

	DiscordRPC.run_callbacks()
	DiscordRPC.refresh()
	if last_presence != ['Nutthin', 'Check it']:
		change_presence(last_presence[0], last_presence[1])
	initalized = true
	print('Discord Initialized')

func clear() -> void:
	initalized = false
	DiscordRPC.clear(true) # it takes a bit for it to actually stop showing

func update(update_id:bool = false, disable:bool = false) -> void:
	if disable: 
		print('Turning off RPC')
		clear()
		DiscordRPC.refresh()
		DiscordRPC.run_callbacks()
		return
	elif !disable and !initalized:
		init_discord()
		
	if !initalized: return
	print('Updating Discord')
	
	if update_id:
		clear()
		DiscordRPC.app_id = _info[int(Prefs.daniel)].id
		DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system() * 100)
	DiscordRPC.large_image = _info[int(Prefs.daniel)].l_img
	DiscordRPC.large_image_text = _info[int(Prefs.daniel)].l_txt
	
	change_presence(last_presence[0], last_presence[1])

	DiscordRPC.run_callbacks()
	print('Updated')
	
func _process(_delta):
	can_rpc = Prefs.allow_rpc and DiscordRPC.get_is_discord_working()
	if can_rpc: 
		DiscordRPC.run_callbacks()

func change_presence(main:String = 'Nutthin', sub:String = 'Check it') -> void:
	last_presence = [main, sub]
	DiscordRPC.details = 'I LOVE DANIEL' if Prefs.daniel else main
	DiscordRPC.state = 'I LOVE DANIEL' if Prefs.daniel else sub
	if can_rpc: DiscordRPC.refresh()
