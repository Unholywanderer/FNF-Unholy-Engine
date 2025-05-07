extends CanvasLayer

var time_existed:float = 0.0
var vol_visible:bool = false
var vol_tween:Tween
var max_tween:Tween
var pressed_key:bool = false
var volume:int = 10:
	set(vol):
		vol = clamp(vol, 0, 10)
		vol_visible = true
		if pressed_key:
			pressed_key = false
			if vol > volume:
				Audio.play_sound('vol/up')
			elif vol < volume:
				Audio.play_sound('vol/down')
			else:
				$Volume/BarsBG/VolBar10.modulate = Color.RED
				if max_tween: max_tween.kill()
				max_tween = create_tween()
				max_tween.tween_property($Volume/BarsBG/VolBar10, 'modulate', Color.WHITE, 0.3)
				Audio.play_sound('vol/max')
			$Volume.position.y = 0
			time_existed = 0
		AudioServer.set_bus_volume_db(0, linear_to_db(vol / 10.0))
		volume = vol
		Prefs.saved_volume = vol
		Prefs.save_prefs()

func _ready():
	volume = Prefs.saved_volume

	Util.center_obj($Volume, 'x')
	$Volume.position.x -= ($Volume.size.x * $Volume.scale.x) / 2.0
	$Other.visible = OS.is_debug_build()

var debug_data:bool = false
func _process(delta):
	if vol_visible:
		if vol_tween: vol_tween.kill()

		$Volume/Percent.text = str(roundi(volume * 10)) +'%'
		for i:int in 10:
			var bar = get_node('Volume/BarsBG/VolBar'+ str(i + 1))
			bar.scale.y = clampf(lerp(0.0 if round(volume) <= i else 1.0, bar.scale.y, exp(-delta * 15)), 0, 1)

		time_existed += delta
		vol_visible = time_existed < 1
		if time_existed >= 1.0:
			vol_tween = create_tween()
			vol_tween.tween_property($Volume, 'position:y', -100, 0.22)

	$FPS.text = 'FPS: '+ str(int(Engine.get_frames_per_second()))
	if OS.is_debug_build():
		var mem:String = String.humanize_size(OS.get_static_memory_usage())
		var mem_peak:String = String.humanize_size(OS.get_static_memory_peak_usage())
		#if tex_mem > texture_memory_peak:
		#	texture_memory_peak = tex_mem

		if Input.is_action_just_pressed('debug_2'):
			debug_data = !debug_data

		var txt_add:String = 'Press (Debug 2) for more info'
		$Other.text = 'Mem: %s / %s\n' % [mem, mem_peak]
		if debug_data:
			var vid_mem:String = String.humanize_size(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
			var tex_mem:String = String.humanize_size(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
			var other_data:Array = [
				vid_mem, tex_mem,
				get_tree().get_node_count(),
				'???',
				Performance.get_monitor(Performance.OBJECT_COUNT),
				Performance.get_monitor(Performance.TIME_PROCESS),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				]
			if get_tree().current_scene != null:
				other_data[3] = get_tree().current_scene.name
			txt_add = 'VMem: %s\nTMem: %s\nNodes: %s\nScene: %s\nAll Objs: %s\nFrm Delay: %s\nDraw Calls: %s' % other_data
		$Other.text += txt_add


func _unhandled_key_input(event:InputEvent):
	if event.is_action_pressed('vol_up') or event.is_action_pressed('vol_down'):
		pressed_key = true
		volume = min(volume + (1 * Input.get_axis('vol_down', 'vol_up')), 10)

	if Input.is_key_pressed(KEY_F4): LuaHandler.reload_scripts()
	if Input.is_key_pressed(KEY_F5): Game.reset_scene()
	if Input.is_key_pressed(KEY_CTRL): # debuggin baby wahoo
		if Input.is_key_pressed(KEY_L): Conductor.playback_rate += 0.05
		if Input.is_key_pressed(KEY_J): Conductor.playback_rate -= 0.05
		if Input.is_key_pressed(KEY_I): Conductor.playback_rate = 1
