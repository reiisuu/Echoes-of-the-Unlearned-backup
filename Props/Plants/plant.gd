class_name Plant extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Hitbox.damaged.connect( takeDamage )
	pass # Replace with function body.

func takeDamage( _hurtbox : Hurtbox ) -> void:
	queue_free()
	pass
