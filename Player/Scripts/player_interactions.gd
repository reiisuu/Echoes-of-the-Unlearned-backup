class_name PlayerInteractions extends Node2D

@onready var player : Player = $".."

# Called when the node enters the scene tree for the first time.
func _ready() :
	player.directionChanged.connect( updateDirection )
	pass # Replace with function body.


func updateDirection( new_direction : Vector2 ) -> void:
	match new_direction:
		Vector2.DOWN:
			rotation_degrees = 90
		Vector2.UP:
			rotation_degrees = -90
		Vector2.LEFT:
			rotation_degrees = 180
		Vector2.RIGHT:
			rotation_degrees = 0
		_:
			rotation_degrees = 0
	pass
