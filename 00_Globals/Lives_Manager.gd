extends Node

var max_lives: int = 3
var current_lives: int = 3

func lose_life():
	current_lives -= 1
	if current_lives <= 0:
		game_over()
	else:
		# Reload current scene to restart the level
		get_tree().reload_current_scene()

func game_over():
	current_lives = max_lives
	# Change this path to whatever your first level or main menu is
	get_tree().change_scene_to_file("res://scenes/scene1.tscn")
	
func reset_game_state():
	current_lives = max_lives
	# Change this path to match your actual first level or menu!
	get_tree().change_scene_to_file("res://scene1.tscn")
