class_name UnholyFormat; extends Resource;

#region Character Json Format
const CHAR_ANIM = {
	'name': '',
	'prefix': '',
	'offsets': [0, 0],
	'framerate': 24,
	'frames': [], #idk maybe
	'loop': false
}
const CHAR_JSON = {
	'animations': [],
	'path': '',
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

const CHART_JSON = {
	'variant': '',
	'events': [],
	'notes': [],
	'sections': [],
	'player': 'bf', 
	'opponent': 'dad', 
	'gf': 'gf',
	'audio_offset': [0, 0],
	'speed': 1.0,
	'song': 'Test'
}
#endregion
