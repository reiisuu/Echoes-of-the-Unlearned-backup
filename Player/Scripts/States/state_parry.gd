class_name State_Parry
extends State

@onready var idle: State = $"../Idle"
@onready var fall: State = $"../Fall"

@export var anim_name: String = "parry"
@export var parry_active_time: float = 0.20
@export var recovery_time: float = 0.14

var _timer: float = 0.0
var _in_recovery: bool = false

func Enter() -> void:
	player.register_behavior_parry()

	_timer = 0.0
	_in_recovery = false

	player.velocity = Vector2.ZERO
	player.is_parrying = true
	player.parry_successful = false

	if player.sprite:
		player.sprite.stop()
		player.sprite.frame = 0
		player.sprite.play(anim_name)

func Exit() -> void:
	player.is_parrying = false
	player.parry_successful = false

func process(delta: float) -> State:
	_timer += delta

	if not _in_recovery:
		player.is_parrying = true

		# Successful parry is handled immediately by player.gd now.
		if player.parry_successful:
			player.is_parrying = false
			player.parry_successful = false

			if player.is_on_floor():
				return idle
			return fall

		if _timer >= parry_active_time:
			player.is_parrying = false
			_in_recovery = true
			_timer = 0.0
			return null

		return null

	player.is_parrying = false

	if _timer >= recovery_time:
		if player.is_on_floor():
			return idle
		return fall

	return null

func physics(delta: float) -> State:
	if not player.is_on_floor():
		player.apply_air_gravity(delta)

	player.velocity.x = 0.0
	player.move_and_slide()
	return null
