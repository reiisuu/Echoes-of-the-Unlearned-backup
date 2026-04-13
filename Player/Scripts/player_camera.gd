class_name PlayerCamera
extends Camera2D

func _ready() -> void:
	make_current()

	if not LevelManager.tileMapBoundsChanged.is_connected(update_limits):
		LevelManager.tileMapBoundsChanged.connect(update_limits)

	if not LevelManager.current_tilemap_bounds.is_empty():
		update_limits(LevelManager.current_tilemap_bounds)

func update_limits(bounds: Array[Vector2]) -> void:
	if bounds.is_empty() or bounds.size() < 2:
		print("PlayerCamera: invalid bounds")
		return

	var left: float = bounds[0].x
	var top: float = bounds[0].y
	var right: float = bounds[1].x
	var bottom: float = bounds[1].y

	var map_width: float = right - left
	var map_height: float = bottom - top
	var screen_size: Vector2 = get_viewport_rect().size

	if map_width <= 0 or map_height <= 0:
		print("PlayerCamera: bounds size invalid -> ", bounds)
		return

	# If the map is smaller than the screen, camera limits can pin the camera.
	# So skip applying limits in that case.
	if map_width <= screen_size.x:
		limit_left = -10000000
		limit_right = 10000000
	else:
		limit_left = int(left)
		limit_right = int(right)

	if map_height <= screen_size.y:
		limit_top = -10000000
		limit_bottom = 10000000
	else:
		limit_top = int(top)
		limit_bottom = int(bottom)

	print("Camera limits set:")
	print("Left: ", limit_left)
	print("Top: ", limit_top)
	print("Right: ", limit_right)
	print("Bottom: ", limit_bottom)
	print("Map size: ", map_width, " x ", map_height)
	print("Screen size: ", screen_size)
