class_name State_Slam
extends State

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"

func Enter() -> void:
	player.register_behavior_slam_attack()
	player.start_slam()
	player.play_effect("slam")

func Exit() -> void:
	player.stop_effect("slam")
	player.end_slam()
	

func Process(_delta: float) -> State:
	if player.is_on_floor():
		if abs(player.direction.x) > 0:
			return walk
		return idle

	return null

func Physics(_delta: float) -> State:
	player.velocity.x = 0.0
	player.velocity.y = player.slam_speed
	player.move_and_slide()
	return null

func HandleInput(_event: InputEvent) -> State:
	return null
