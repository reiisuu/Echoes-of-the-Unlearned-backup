extends TextureButton

func _on_pressed() -> void:
	# Get the current window mode
	var current_mode = DisplayServer.window_get_mode()
	
	# Check if it is currently in fullscreen
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		# Switch to windowed mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		# Switch to fullscreen mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
