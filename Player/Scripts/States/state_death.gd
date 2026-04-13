class_name State_Death
extends State

@onready var idle: State = $"../Idle"

var death_started: bool = false

func Enter() -> void:
	death_started = false

	player.velocity = Vector2.ZERO
	player.invulnerable = true

	if player.hitbox:
		player.hitbox.monitoring = false

	if player.slam_hitbox:
		player.slam_hitbox.set_deferred("monitoring", false)

	if player.charged_attack_hurtbox:
		player.charged_attack_hurtbox.set_deferred("monitoring", false)

	player.is_slamming = false
	player.is_healing = false
	player.is_charged_attacking = false
	player.is_parrying = false

	player.stop_effect()
	player.stop_enrage()

	player.updateAnimation("idle")

func Exit() -> void:
	death_started = false

func Process(_delta: float) -> State:
	return null

func Physics(_delta: float) -> State:
	player.velocity = Vector2.ZERO

	if not death_started:
		death_started = true
		_do_death_reset()

	return null

func _do_death_reset() -> void:
	await player.get_tree().create_timer(0.6).timeout

	player.global_position = player.checkpoint_position
	player.velocity = Vector2.ZERO
	player.hp = player.maxHp
	player.invulnerable = false

	if player.hitbox:
		player.hitbox.monitoring = true

	player.stop_effect()
	player.updateAnimation("idle")
	state_machine.ChangeState(idle)
