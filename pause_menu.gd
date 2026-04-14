extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Start with the menu hidden and non-interactive
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_player.play("RESET")
	process_mode = Node.PROCESS_MODE_ALWAYS

func resume():
	get_tree().paused = false
	animation_player.play_backwards("blur")
	# Hide the menu and stop it from blocking clicks
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await animation_player.animation_finished # Wait for blur to fade before hiding
	if !get_tree().paused: # Double check we haven't re-paused
		hide()
	
func pause():
	# Show the menu and make it block/detect clicks
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	animation_player.play("blur")

func testEsc():
	if Input.is_action_just_pressed("esc"):
		if get_tree().paused:
			resume()
		else:
			pause()

func _process(_delta):
	testEsc()

# --- Button Signals ---

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_mainmenu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
