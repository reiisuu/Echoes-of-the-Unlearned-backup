extends Node

var current_tilemap_bounds: Array[Vector2] = []

signal tileMapBoundsChanged(bounds: Array[Vector2])

var scenes: Array[String] = [
	"res://scene1.tscn",
	"res://scene2.tscn",
	"res://scene3.tscn"
]

func changeTileMapBounds(bounds: Array[Vector2]) -> void:
	current_tilemap_bounds = bounds
	tileMapBoundsChanged.emit(bounds)
	print("LevelManager bounds updated: ", bounds)

func get_next_scene(current_scene_path: String) -> String:
	var index := scenes.find(current_scene_path)

	if index == -1:
		push_error("Current scene not found in LevelManager scenes: " + current_scene_path)
		return ""

	if index >= scenes.size() - 1:
		push_warning("Already at the last scene: " + current_scene_path)
		return ""

	return scenes[index + 1]
