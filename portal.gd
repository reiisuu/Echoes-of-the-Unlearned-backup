extends Area2D

@export_file("*.tscn") var next_scene: String = ""

var transitioning := false

func _on_body_entered(body: Node) -> void:
	if transitioning:
		return

	if body.is_in_group("player"):
		transitioning = true
		set_deferred("monitoring", false)
		call_deferred("_do_transition")

func _do_transition() -> void:
	var target_scene := next_scene

	if target_scene == "":
		var current_scene_path := get_tree().current_scene.scene_file_path
		target_scene = LevelManager.get_next_scene(current_scene_path)

	if target_scene == "":
		push_error("No target scene found.")
		transitioning = false
		set_deferred("monitoring", true)
		return

	if not ResourceLoader.exists(target_scene):
		push_error("Scene does not exist: " + target_scene)
		transitioning = false
		set_deferred("monitoring", true)
		return

	if Transition == null:
		push_error("Transition autoload is missing.")
		transitioning = false
		set_deferred("monitoring", true)
		return

	Transition.fade_to_scene(target_scene)
