extends Enemy
class_name Boss

enum BossPhase {
	PHASE_1 = 1,
	PHASE_2 = 2,
	PHASE_3 = 3
}

@export var boss_max_hp: int = 20

@export var phase_1_speed: float = 55.0
@export var phase_2_speed: float = 75.0
@export var phase_3_speed: float = 100.0

@export var attack_cooldown_time: float = 1.0
@export var heavy_cooldown_time: float = 2.0
@export var stomp_cooldown_time: float = 4.0
@export var feint_cooldown_time: float = 3.0

var current_phase: int = BossPhase.PHASE_1
var pending_phase: int = BossPhase.PHASE_1

var boss_move_speed: float = 55.0

var is_attacking: bool = false
var is_phase_changing: bool = false

var attack_cd: float = 0.0
var heavy_cd: float = 0.0
var stomp_cd: float = 0.0
var feint_cd: float = 0.0

var player_in_attack_range: bool = false
var current_attack_name: String = ""

@onready var stomp_hitbox: Area2D = get_node_or_null("StompHitbox")
@onready var attack_range_area: Area2D = get_node_or_null("AttackRange")

@onready var attack_state: EnemyState = $EnemyStateMachine/Attack
@onready var heavy_attack_state: EnemyState = $EnemyStateMachine/HeavyAttack
@onready var stomp_state: EnemyState = $EnemyStateMachine/Stomp
@onready var feint_state: EnemyState = $EnemyStateMachine/Feint
@onready var phase_transition_state: EnemyState = $EnemyStateMachine/PhaseTransition

func _ready() -> void:
	hp = boss_max_hp
	super._ready()

	print("BOSS READY")
	print("boss sprite = ", sprite)
	if sprite and sprite.sprite_frames:
		print("boss animations = ", sprite.sprite_frames.get_animation_names())

	set_main_hitbox_enabled(false)
	set_stomp_hitbox_enabled(false)

	if attack_range_area:
		print("ATTACK RANGE NODE = ", attack_range_area)
		print("ATTACK RANGE monitoring = ", attack_range_area.monitoring)

		var attack_shape: CollisionShape2D = attack_range_area.get_node_or_null("CollisionShape2D")
		print("ATTACK RANGE shape = ", attack_shape)
		if attack_shape:
			print("ATTACK RANGE shape disabled = ", attack_shape.disabled)

		print("ATTACK RANGE collision layer = ", attack_range_area.collision_layer)
		print("ATTACK RANGE collision mask = ", attack_range_area.collision_mask)

	apply_phase_stats()

func _process(delta: float) -> void:
	_tick_cooldowns(delta)

func _tick_cooldowns(delta: float) -> void:
	attack_cd = max(attack_cd - delta, 0.0)
	heavy_cd = max(heavy_cd - delta, 0.0)
	stomp_cd = max(stomp_cd - delta, 0.0)
	feint_cd = max(feint_cd - delta, 0.0)

func has_player() -> bool:
	return player != null and is_instance_valid(player)

func distance_to_player() -> float:
	if not has_player():
		return INF
	return global_position.distance_to(player.global_position)

func direction_to_player() -> Vector2:
	if not has_player():
		return Vector2.ZERO
	return (player.global_position - global_position).normalized()

func face_player() -> void:
	var dir := direction_to_player()
	if dir != Vector2.ZERO:
		setDirection(Vector2(sign(dir.x), 0))

func is_player_in_chase_range() -> bool:
	if not has_player():
		return false
	return player_in_range

func is_player_in_attack_range() -> bool:
	if not has_player():
		return false
	return player_in_attack_range

func get_phase_from_hp() -> int:
	var hp_ratio := float(hp) / float(max(boss_max_hp, 1))

	if hp_ratio <= 0.35:
		return BossPhase.PHASE_3
	elif hp_ratio <= 0.70:
		return BossPhase.PHASE_2
	else:
		return BossPhase.PHASE_1

func needs_phase_transition() -> bool:
	pending_phase = get_phase_from_hp()
	return pending_phase != current_phase

func begin_phase_transition() -> void:
	is_phase_changing = true
	is_attacking = false
	current_attack_name = ""
	velocity = Vector2.ZERO
	set_main_hitbox_enabled(false)
	set_stomp_hitbox_enabled(false)

func finish_phase_transition() -> void:
	current_phase = pending_phase
	apply_phase_stats()
	is_phase_changing = false

func apply_phase_stats() -> void:
	match current_phase:
		BossPhase.PHASE_1:
			boss_move_speed = phase_1_speed
		BossPhase.PHASE_2:
			boss_move_speed = phase_2_speed
		BossPhase.PHASE_3:
			boss_move_speed = phase_3_speed

func choose_attack_state() -> EnemyState:
	if is_phase_changing:
		return null

	if needs_phase_transition():
		return phase_transition_state

	# priority can be changed anytime later
	if current_phase >= BossPhase.PHASE_3 and feint_cd <= 0.0 and feint_state != null:
		print("BOSS CHOOSE: FEINT")
		return feint_state

	if current_phase >= BossPhase.PHASE_2 and stomp_cd <= 0.0 and stomp_state != null:
		print("BOSS CHOOSE: STOMP")
		return stomp_state

	if current_phase >= BossPhase.PHASE_2 and heavy_cd <= 0.0 and heavy_attack_state != null:
		print("BOSS CHOOSE: HEAVY")
		return heavy_attack_state

	if attack_cd <= 0.0 and attack_state != null:
		print("BOSS CHOOSE: ATTACK")
		return attack_state

	print("BOSS CHOOSE: NONE")
	return null

func start_attack(attack_name: String = "attack") -> void:
	is_attacking = true
	current_attack_name = attack_name
	velocity = Vector2.ZERO
	face_player()

	set_main_hitbox_enabled(false)
	set_stomp_hitbox_enabled(false)

func finish_attack(attack_name: String) -> void:
	is_attacking = false
	current_attack_name = ""
	velocity = Vector2.ZERO

	set_main_hitbox_enabled(false)
	set_stomp_hitbox_enabled(false)

	match attack_name:
		"attack":
			attack_cd = attack_cooldown_time
		"heavy":
			heavy_cd = heavy_cooldown_time
		"stomp":
			stomp_cd = stomp_cooldown_time
		"feint":
			feint_cd = feint_cooldown_time

func set_main_hitbox_enabled(enabled: bool) -> void:
	if hitbox:
		hitbox.monitoring = enabled
		var shape: CollisionShape2D = hitbox.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled

func set_stomp_hitbox_enabled(enabled: bool) -> void:
	if stomp_hitbox:
		stomp_hitbox.monitoring = enabled
		var shape: CollisionShape2D = stomp_hitbox.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled

func _on_attack_range_body_entered(body: Node) -> void:
	print("ATTACK RANGE BODY ENTERED: ", body)
	if body is Player:
		player_in_attack_range = true
		print("BOSS ATTACK RANGE: ENTER")

func _on_attack_range_body_exited(body: Node) -> void:
	print("ATTACK RANGE BODY EXITED: ", body)
	if body is Player:
		player_in_attack_range = false
		print("BOSS ATTACK RANGE: EXIT")
