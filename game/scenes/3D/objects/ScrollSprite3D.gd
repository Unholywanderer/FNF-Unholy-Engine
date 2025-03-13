class_name ScrollSprite3D; extends Node3D;

@export var scroll_factor:Vector2 = Vector2.ONE

var cam:Camera3D
func _process(_delta):
	cam = get_viewport().get_camera_3d()
	#if cam != null:
	#	position = (cam.get_screen_center_position() - (get_viewport_rect().size / 2.0)) * (Vector3.ONE - scroll_factor)
