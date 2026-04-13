class_name EnemyStateWander
extends EnemyState

@export var anim_name: String = "walk"
@export var wander_speed: float = 20.0

@export_category("AI")
@export var state_duration: float = 1.5
@export var next_state: EnemyState
@export var chase_state: EnemyState

var _timer: float = 0.0
var _direction: Vector2 = Vector2.ZERO

func Enter() -> void:
	_timer = state_duration
	_direction = Vector2.RIGHT if randi() % 2 == 0 else Vector2.LEFT
	enemy.setDirection(_direction)
	enemy.updateAnimation(anim_name)
	# print("ENTER WANDER")

func Exit() -> void:
	enemy.velocity = Vector2.ZERO

func process(_delta: float) -> EnemyState:
	if enemy.player_in_range:
		print("WANDER: player detected")
		if chase_state != null:
			print("WANDER -> CHASE")
			return chase_state
		else:
			print("WANDER: chase_state is NULL")

	_timer -= _delta
	if _timer <= 0.0:
		return next_state

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity.x = _direction.x * wander_speed
	return null
