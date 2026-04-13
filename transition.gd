extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

var is_transitioning := false

func fade_to_scene(scene_path: String) -> void:
	if is_transitioning:
		return

	is_transitioning = true

	anim.play("fade_in")
	await anim.animation_finished

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to: " + scene_path)
		is_transitioning = false
		return

	await get_tree().process_frame
	await get_tree().process_frame

	anim.play("fade_out")
	await anim.animation_finished

	is_transitioning = false
