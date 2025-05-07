class_name Osu; extends Chart;
# Stole most if not all of this

var osu_file:Array
func parse_chart(data):
	var circ_size = int(get_data('CircleSize'))
	var bpm_mill = get_time_points()[1]

	for h in osu_file.size():
		if osu_file[h].begins_with('[HitObjects]'):
			for i in range(h, osu_file.size() - 1):
				if !(osu_file[i].length() > 0 && osu_file[i].contains(',')): continue # Not a hit object, skip
				var hit_obj:Array = []
				var hit_data = osu_file[i].split(',')
				for n in hit_data.size():
					if hit_data[n].contains(':'):
						hit_data[n] = hit_data[n].split(':')[0]

					hit_obj.append(int(hit_data[n]))

				var n_time:float = hit_obj[2]
				var n_data:int = floor(hit_obj[0] * circ_size / 512.0)
				var n_len:float = (hit_obj[5] - n_time) if (hit_obj[5] > 0) else 0
				#var noteSec = int(n_time / (bpm_mill * 4.0))

				add_note([n_time, n_data, n_len > 0, n_len, true, ''])
			break
	return return_notes

func get_data(to_get:String):
	for i:String in osu_file:
		if i.begins_with(to_get):
			var to_return = i.split(to_get +':')[1].strip_edges()
			return to_return.replace('\r', '').replace('\n', '')
	return ''

func get_time_points():
	for i in osu_file.size():
		if osu_file[i].begins_with('[TimingPoints]'):
			var t_p:Array = []
			for point in osu_file[i + 1].split(','):
				t_p.append(float(point))
			return t_p
	return []

func load_file(song:String) -> Dictionary:
	var funny_data:Dictionary = {}
	osu_file = FileAccess.open('res://assets/songs/'+ song +'/charts/hard.osu', FileAccess.READ).get_as_text().split('\n')
	if int(get_data('Mode')) != 3: return {}

	var time_points = get_time_points()
	#var offset = time_points[0]
	var speed = float(get_data('OverallDifficulty'))
	#var hit_objs #= parse_chart()

	#var sections:Array = []
	#for i in hit_objs.size():
	#	var newSec
	#	if hit_objs.get(i) != null:
	#		newSec.sectionNotes = hit_objs.get(i)
	#	sections.append(newSec)

	funny_data.song = get_data('Title')
	funny_data.speed = Util.round_d(speed / 2.5, 1)
	funny_data.bpm = Util.round_d(60000.0 / time_points[1], 1)
	#funny_data.notes = parse_chart(osu_file)
	funny_data.player1 = 'bf'
	funny_data.player2 = 'dad'
	funny_data.gfVersion = 'gf'

	return funny_data
