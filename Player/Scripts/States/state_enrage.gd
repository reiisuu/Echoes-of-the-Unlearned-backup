class_name State_Enrage
extends State

@export var enrage_cast_time: float = 0.35

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var run: State = $"../Run"
@onready var fall: State = $"../Fall"

var timer: float = 0.0
var activated: bool = false

func Enter() -> void:
	if not player.can_enrage:
		return
	timer = 0.0
	activated = false
	player.velocity.x = 0.0

	if player.sprite.sprite_frames.has_animation("enrage"):
		player.updateAnimation("enrage")
	else:
		player.updateAnimation("idle")

func Exit() -> void:
	pass

func Process(delta: float) -> State:
	timer += delta

	if not activated:
		activated = true
		player.start_enrage()

	if timer >= enrage_cast_time:
		if not player.is_on_floor():
			return fall

		if abs(player.direction.x) > 0:
			if player.isRunning:
				return run
			return walk

		return idle

	return null

func Physics(_delta: float) -> State:
	player.velocity.x = 0.0
	return null
