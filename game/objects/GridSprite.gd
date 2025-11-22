class_name Grid extends Node2D
#FLX GRID
#originally by Richard Davey / Photon Storm
#port my mae!!!!

#this version returns a texture, how you handle it is up to u
var width:float = 0
var height:float = 0

var cell:Vector2 = Vector2.ZERO #width/height of the cells
var size:Vector2 = Vector2.ZERO #width/height of the Sprite

var alternate:bool #stripes or checkers

var rotated:bool = false #rotate for stripes

var color_1:Color
var color_2:Color

func create(cell_size := Vector2(10,10), sprite_size := Vector2(-1,-1),
   altern_patt := true, c_1 := Color.hex(0xe7e6e6ff), c_2 := Color(0xd9d5d5ff)) -> Texture2D:

	var SCREEN = DisplayServer.screen_get_size()

	if sprite_size.x == -1:
		sprite_size.x = SCREEN.x
	if sprite_size.y == -1:
		sprite_size.y = SCREEN.y

	if sprite_size < cell_size:
		return null

	if rotated:
		sprite_size = Vector2(sprite_size.y, sprite_size.x)

	if cell == Vector2.ZERO: cell = cell_size
	if size == Vector2.ZERO: size = sprite_size
	alternate = altern_patt
	if c_1: color_1 = c_1
	if c_2: color_2 = c_2

	var grid = create_grid()
	if rotated:
		grid.rotate_90(CLOCKWISE)

	var output = ImageTexture.create_from_image(grid);
	return output


func create_grid() -> Image:
	#How many cells can we fit into the width/height?
	#(round it UP if not even, then trim back)
	size.x = int(size.x)
	size.y = int(size.y)

	cell.x = int(cell.x)
	cell.y = int(cell.y)

	var row_color:Color = color_1
	var last_color:Color = color_1

	var grid := Image.create_empty(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)

	#swap the last_color value if the number of cells in a row isnt even
	var y:int = 0
	while y <= size.y:
		if y > 0 and last_color == row_color and alternate:
			last_color = color_2 if (last_color == color_1) else color_1
		else: if y > 0 and last_color != row_color and not alternate:
			last_color = color_1

		var x:int = 0
		while x <= size.x:
			if x == 0: row_color = last_color

			fill_rect(grid, x, y, last_color)
			if last_color == color_1:
				last_color = color_2
			else:
				last_color = color_1

			x += int(cell.x);
		y += int(cell.y);

		width = x - cell.x
	height = y - cell.y
	return grid;

func fill_rect(grid, x, y, last_color) -> void:
	for dy in range(cell.y):
		for dx in range(cell.x):
			var px = x + dx
			var py = y + dy
			if px < size.x and py < size.y:
				grid.set_pixel(px, py, last_color)
