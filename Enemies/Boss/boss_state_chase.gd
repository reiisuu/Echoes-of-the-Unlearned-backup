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

@export var emergency_backstep_distance: float = 36.0
@export var backstep_chance_close: float = 0.6
@export var backstep_chance_normal: float = 0.35

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

	if boss.in_phase_2 and phase_transition != null and not boss.has_meta("phase_transition_done"):
		boss.set_meta("phase_transition_done", true)
		return phase_transition

	# backstep stays high priority
	if boss.can_use_attack("backstep"):
		if dist <= emergency_backstep_distance and randf() < backstep_chance_close:
			return backstep

		if dist <= boss.backstep_trigger_distance:
			if boss.should_backstep(dist) or randf() < backstep_chance_normal:
				return backstep

	# punish stays reactive
	if dist <= boss.punish_distance and boss.should_force_punish(dist):
		return punish

	var choices: Array[Dictionary] = []

	# close range
	if dist <= normal_attack_range:
		if boss.can_use_attack("normal"):
			_add_weighted_choice(choices, attack, "normal", 3)
		if boss.can_use_attack("heavy"):
			_add_weighted_choice(choices, heavy, "heavy", 2)
		if boss.can_use_attack("stomp") and boss.in_phase_2:
			_add_weighted_choice(choices, stomp, "stomp", 1)

	# mid range
	elif dist <= heavy_attack_range:
		if boss.can_use_attack("heavy"):
			_add_weighted_choice(choices, heavy, "heavy", 3)
		if boss.can_use_attack("normal") and dist <= normal_attack_range + 10.0:
			_add_weighted_choice(choices, attack, "normal", 1)
		if boss.can_use_attack("stomp"):
			_add_weighted_choice(choices, stomp, "stomp", 2)

	# long range
	elif dist <= stomp_attack_range:
		if boss.can_use_attack("stomp"):
			_add_weighted_choice(choices, stomp, "stomp", 3)
		if boss.can_use_attack("heavy"):
			_add_weighted_choice(choices, heavy, "heavy", 1)

	var chosen_state := _pick_non_repeating_choice(choices, boss.last_attack_used)
	if chosen_state != null:
		return chosen_state

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

func _add_weighted_choice(choices: Array[Dictionary], state: EnemyState, attack_name: String, weight: int) -> void:
	for i in range(weight):
		choices.append({
			"state": state,
			"name": attack_name
		})

func _pick_non_repeating_choice(choices: Array[Dictionary], last_attack_name: String) -> EnemyState:
	if choices.is_empty():
		return null

	var filtered: Array[Dictionary] = []

	for choice in choices:
		if String(choice["name"]) != last_attack_name:
			filtered.append(choice)

	var pool := filtered if not filtered.is_empty() else choices
	var picked: Dictionary = pool[randi() % pool.size()]
	return picked["state"]
