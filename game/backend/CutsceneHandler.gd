class_name Cutscene; extends Resource;

signal skipped
@warning_ignore("unused_signal")
signal finished
@warning_ignore("unused_signal")
signal video_skipped
signal video_finished

var on_video_finish:Callable = func(): # if overwritten, make sure video is cleared sometime
	video.queue_free()
	video_finished.emit()

var max_time:float = 0.0:
	set(time):
		max_time = time
		add_timed_event(time, finished.emit)

var cutscene_in_progress:bool = false
var timed_events:Array = []
func add_timed_event(time:float, event:Callable) -> void:
	Game.scene.get_tree().create_timer(abs(time), false).timeout.connect(event)

@warning_ignore("unused_parameter")
func start_dialogue(file:String = 'dialogue', on_finish:Callable = func(): pass, delay:float = 0) -> void:
	var dia = load("res://game/objects/ui/dialogue_box.tscn").instantiate()
	dia.load_legacy(file)
	dia.dialogue_finished.connect(on_finish)
	Game.scene.ui.add_behind(dia)
	dia.play_dialogue()

var video:VideoStreamPlayer
@warning_ignore("unused_parameter")
func play_video(vid_name:String, auto_play:bool = true, loop:bool = false, add_to = null) -> void:
	if video: video.queue_free()
	var new_video:VideoStreamPlayer = VideoStreamPlayer.new()
	new_video.stream = FFmpegVideoStream.new()
	new_video.stream.file = 'res://assets/videos/%s.mp4' % [vid_name]
	if add_to != null:
		if add_to is Callable: add_to.call(new_video)
		else: add_to.add_child(new_video)

		if auto_play:
			var center = Vector2(Game.screen[0] / 2.0, Game.screen[1] / 2.0)
			new_video.position = center - ((new_video.size / Vector2(2.0, 2.0)) * new_video.scale)
			new_video.play()
	video = new_video
	video.finished.connect(on_video_finish)
	#return new_video

var _hold_time:float = 0.0
func _process(delta:float) -> void:
	if video:
		if Input.is_action_pressed(&"accept"): _hold_time += delta
		if _hold_time >= 1:
			_hold_time = 0
			skipped.emit()
			video.finished.emit()
			if video: video.queue_free()
			# in case you have it set to auto delete after its finished somewhere
			# just do a quick null check before we remove
