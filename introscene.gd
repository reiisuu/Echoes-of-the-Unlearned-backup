extends Node2D

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("intro") # make sure animation name matches
	$AudioStreamPlayer.play()
	$AnimationPlayer.play("intro")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	pass # Replace with function body.
	
