class_name UnholyFormat; extends Resource;

#region Character Json Format
## Default character animation format for the character json.
## [code]flip_x[/code] and [code]flip_y[/code] are optional,
## only added when specified
const CHAR_ANIM = {
	'name': '',
	'prefix': '',
	'offsets': [0, 0],
	'framerate': 24,
	'frames': [], #idk maybe
	#'flip_x': false, #optional
	#'flip_y': false, #will only be added if it exists
	'loop': false
}

## Default character json format
const CHAR_JSON = {
	'animations': [],
	'path': 'characters/bf/char',
	'death_char': 'bf-dead',
	'icon': 'bf',
	'facing_left': false,
	'antialiasing': true,
	'cam_offset': [0, 0],
	'pos_offset': [0, 0],
	'sing_dur': 4,
	'scale': 1
}
#endregion

#region Chart Format
const SECTION_FORMAT = {
	'mustHitSection': true,
	'gfSection': false,
	'altAnim': false,
	'bpm': 100,
	'changeBPM': false,
	'beats': 4
}

#const CHART_JSON = {
#	'variant': '',
#	'events': [],
#	'notes': [],
#	'sections': [],
#	'player': 'bf',
#	'opponent': 'dad',
#	'gf': 'gf',
	#'audio_offset': [0, 0],
#	'speed': 1.0,
#	'song': 'Test'
#}

## Chart format used for the Chart Editor. Should be converted back to another
## chart type afterwards
const EDITOR_CHART = {
	'notes': [],
	'events': [],
	'sections': [], # if the song has sections, hold them all here
	'player': 'bf',
	'gf': 'gf',
	'opponent': 'dad',
	'speed': 1.0,
	'song': 'Bopeebo'
}
#endregion
