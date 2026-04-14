class_name BossStateChase
extends EnemyState

@onready var idle: EnemyState = $"../Idle"
@onready var attack: EnemyState = $"../Attack"
@onready var heavy: EnemyState = $"../HeavyAttack"
@onready var stomp: EnemyState = $"../Stomp"
@onready var punish: EnemyState = $"../Punish"
@onready var backstep: EnemyState = $"../Backstep"
@onready var phase_transition: EnemyState = $"../PhaseTransition"

@export var normal_attack_range: float = 36.0
@export var heavy_attack_range: float = 78.0
@export var stomp_attack_range: float = 120.0
@export var stop_distance: float = 18.0

func Enter() -> void:
	enemy.updateAnimation("walk")
	enemy.reset_attack_window()

func Exit() -> void:
	enemy.velocity.x = 0.0
	enemy.reset_attack_window()

func process(_delta: float) -> EnemyState:
	if enemy.player == null:
		return idle

	var boss := enemy as Boss
	if boss == null:
		return idle

	var dx := enemy.player.global_position.x - enemy.global_position.x
	var dist: float = abs(dx)

	boss.face_player(dx)

	# optional one-time phase transition
	if boss.in_phase_2 and phase_transition != null and not boss.has_meta("phase_transition_done"):
		boss.set_meta("phase_transition_done", true)
		return phase_transition

	# highest priority defensive reaction when player is too close
	if dist <= boss.backstep_trigger_distance:
		if boss.should_backstep(dist):
			return backstep

	# punish committed player if nearby
	if dist <= boss.punish_distance:
		if boss.should_force_punish(dist):
			return punish

	# close-range primary attack
	if dist <= normal_attack_range:
		if boss.can_use_attack("normal"):
			return attack

		# fallback if normal is on cooldown
		if boss.can_use_attack("heavy") and dist <= heavy_attack_range:
			return heavy

	# mid-range attack
	if dist <= heavy_attack_range:
		if boss.can_use_attack("heavy"):
			return heavy

		# fallback if heavy is on cooldown and player is still close enough
		if boss.can_use_attack("normal") and dist <= normal_attack_range:
			return attack

	# longer-range pressure
	if dist <= stomp_attack_range:
		if boss.can_use_attack("stomp"):
			return stomp

		# fallback so boss still feels active if stomp is cooling down
		if boss.can_use_attack("heavy") and dist <= heavy_attack_range:
			return heavy

	return null

func physics(_delta: float) -> EnemyState:
	if enemy.player == null:
		enemy.velocity.x = 0.0
		return null

	var boss := enemy as Boss
	if boss == null:
		enemy.velocity.x = 0.0
		return null

	var dx := enemy.player.global_position.x - enemy.global_position.x
	var dist: float = abs(dx)
	var dir: float = sign(dx)

	boss.face_player(dx)

	if dir == 0.0 or dist <= stop_distance:
		enemy.velocity.x = 0.0
	else:
		enemy.velocity.x = dir * boss.get_chase_speed()

	return null
