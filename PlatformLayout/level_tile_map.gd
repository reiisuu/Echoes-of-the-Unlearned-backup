class_name LevelTileMap
extends TileMap

func _ready() -> void:
	await get_tree().process_frame
	LevelManager.changeTileMapBounds(get_tilemap_bounds())

func get_tilemap_bounds() -> Array[Vector2]:
	var used_rect: Rect2i = get_used_rect()

	if used_rect.size == Vector2i.ZERO:
		print("LevelTileMap: TileMap is empty")
		return []

	if tile_set == null:
		print("LevelTileMap: no TileSet assigned")
		return []

	var tile_size: Vector2i = tile_set.tile_size

	var top_left := Vector2(
		used_rect.position.x * tile_size.x,
		used_rect.position.y * tile_size.y
	) + global_position

	var bottom_right := Vector2(
		used_rect.end.x * tile_size.x,
		used_rect.end.y * tile_size.y
	) + global_position

	print("TileMap used rect: ", used_rect)
	print("Tile size: ", tile_size)
	print("TileMap bounds: ", top_left, " -> ", bottom_right)

	return [top_left, bottom_right]
