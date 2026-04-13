class_name EnemyStatePhaseTransition
extends EnemyState

@export var anim_name: String = "idle"
@export var transition_duration: float = 1.0
@export var next_state: EnemyState

var _timer: float = 0.0

func Enter() -> void:
	_timer = 0.0
	enemy.velocity = Vector2.ZERO
	enemy.invulnerable = true

	if enemy.hitbox:
		enemy.hitbox.monitoring = false

	enemy.updateAnimation(anim_name)
	print(enemy.name, " ENTER PHASE TRANSITION | phase = ", enemy.current_phase)

	# Phase bonuses
	match enemy.current_phase:
		2:
			enemy.normal_attack_cooldown = 0.5
			enemy.heavy_attack_cooldown = 1.15
			enemy.feint_cooldown = 0.85
		3:
			enemy.normal_attack_cooldown = 0.42
			enemy.heavy_attack_cooldown = 0.95
			enemy.stomp_attack_cooldown = 1.55
			enemy.feint_cooldown = 0.7

func Exit() -> void:
	enemy.invulnerable = false
	enemy.transition_locked = false

func process(delta: float) -> EnemyState:
	_timer += delta

	if _timer >= transition_duration:
		return next_state

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity = Vector2.ZERO
	return null
