class_name JSFParser extends Resource
static var format:Dictionary = {x = 0, y = 0, alpha = 1, scale_x = 1, scale_y = 1}

static func parse(text:String) -> Array[Dictionary]:
	var file:String = FileAccess.get_file_as_string('res://assets/'+ text +'.txt')
	if file.is_empty(): return [format] # just return if nothing is found
	var frames:Array[Dictionary] = []
	for line:String in file.split('\n'):
		var le_mat:Dictionary = format.duplicate(true)

		var line_info:Array = line.split(' ')
		le_mat.x = float(line_info[0])
		le_mat.y = float(line_info[1])
		le_mat.alpha = float(line_info[2]) / 100.0 if line_info[2] != 'undefined' else 1.0
		if line_info.size() > 3: le_mat.scale_x = float(line_info[3])
		if line_info.size() > 4: le_mat.scale_y = float(line_info[4])

		frames.append(le_mat)
	return frames
