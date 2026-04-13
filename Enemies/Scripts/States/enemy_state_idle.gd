class_name EnemyStateIdle
extends EnemyState

@export var anim_name: String = "idle"

@export_category("AI")
@export var state_duration_min: float = 0.5
@export var state_duration_max: float = 1.5
@export var after_idle_state: EnemyState
@export var chase_state: EnemyState

var _timer: float = 0.0

func Enter() -> void:
	enemy.direction = Vector2.ZERO
	enemy.velocity = Vector2.ZERO
	_timer = randf_range(state_duration_min, state_duration_max)
	enemy.updateAnimation(anim_name)
	# print("ENTER IDLE")

func process(_delta: float) -> EnemyState:
	if enemy.player_in_range:
		print("IDLE: player detected")
		if chase_state != null:
			print("IDLE -> CHASE")
			return chase_state
		else:
			print("IDLE: chase_state is NULL")

	_timer -= _delta
	if _timer <= 0.0:
		return after_idle_state

	return null

func physics(_delta: float) -> EnemyState:
	return null
