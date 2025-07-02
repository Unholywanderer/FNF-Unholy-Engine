extends Node2D

func _unhandled_input(event:InputEvent) -> void:
	Game.switch_scene('menus/freeplay_classic')
