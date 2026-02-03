extends Node2D

const INFO = [
	{id = 1225971084998737952, l_img = 'deedee_phantonm', l_txt = 'out here unholy-ing baby'},
	{id = 1227081103932657664, l_img = 'daniel', l_txt = 'I LOVE DANIEL'}
]

var initalized:bool = false
var discord_exists:bool = true # aint this a bitch, it dont work, ill just make it true

var can_rpc:bool:
	get: return Prefs.allow_rpc and discord_exists

var last_presence:Array[String] = ['Nutthin', 'Check it'] # hold the actual presence text, so it can swap
func init_discord() -> void:
	if initalized or !discord_exists: return
	print('Initializing Discord...')

	DiscordRPC.app_id = INFO[int(Prefs.daniel)].id
	DiscordRPC.large_image = INFO[int(Prefs.daniel)].l_img
	DiscordRPC.large_image_text = INFO[int(Prefs.daniel)].l_txt
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())

	DiscordRPC.run_callbacks()
	DiscordRPC.refresh()
	if last_presence != ['Nutthin', 'Check it']:
		change_presence(last_presence[0], last_presence[1])
	initalized = true
	print('Discord Initialized')

func clear() -> void:
	if !discord_exists: return
	initalized = false
	DiscordRPC.clear(true) # it takes a bit for it to actually stop showing

func update(update_id:bool = false, disable:bool = false) -> void:
	if !discord_exists:
		return
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
		DiscordRPC.app_id = INFO[int(Prefs.daniel)].id
		DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.large_image = INFO[int(Prefs.daniel)].l_img
	DiscordRPC.large_image_text = INFO[int(Prefs.daniel)].l_txt

	change_presence(last_presence[0], last_presence[1])

	DiscordRPC.run_callbacks()
	print('Updated')

func _process(_delta):
	if !can_rpc: return
	DiscordRPC.run_callbacks()

func change_presence(main:String = 'Nutthin', sub:String = 'Check it') -> void:
	if !discord_exists: return
	last_presence = [main, sub]
	DiscordRPC.details = 'I LOVE DANIEL' if Prefs.daniel else main
	DiscordRPC.state = 'I LOVE DANIEL' if Prefs.daniel else sub
	if can_rpc: DiscordRPC.refresh()
