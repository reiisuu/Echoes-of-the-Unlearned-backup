class_name Enemy
extends CharacterBody2D

signal directionChanged(new_direction: Vector2)
signal enemyDamaged(hurtbox: Hurtbox)
signal enemyDestroyed(hurtbox: Hurtbox)

@export var punish_followup_chance_phase_1: float = 0.15
@export var punish_followup_chance_phase_2: float = 0.30
@export var punish_followup_chance_phase_3: float = 0.45

@export var hp: int = 3
@export var max_hp: int = 3
@export var gravity: float = 2200.0
@export var max_fall_speed: float = 1200.0

# =========================
# ADAPTIVE BOSS MEMORY
# =========================
@export var memory_decay_per_second: float = 0.8
@export var close_range_threshold: float = 55.0
@export var far_range_threshold: float = 135.0

@export var normal_attack_cooldown: float = 0.65
@export var heavy_attack_cooldown: float = 1.4
@export var stomp_attack_cooldown: float = 2.0
@export var feint_cooldown: float = 1.1
@export var punish_attack_cooldown: float = 0.9

var normal_attack_cd_timer: float = 0.0
var heavy_attack_cd_timer: float = 0.0
var stomp_attack_cd_timer: float = 0.0
var feint_cd_timer: float = 0.0
var punish_attack_cd_timer: float = 0.0

var recent_dash_score: float = 0.0
var recent_parry_score: float = 0.0
var recent_heal_score: float = 0.0
var recent_jump_score: float = 0.0
var recent_greedy_score: float = 0.0

var close_range_time: float = 0.0
var far_range_time: float = 0.0

var last_player_hp: int = -1
var last_player_y: float = 0.0
var last_seen_distance: float = 99999.0
var last_attack_used: String = ""

# =========================
# PHASES
# =========================
@export var enable_phases: bool = true
@export var phase_two_threshold: float = 0.65
@export var phase_three_threshold: float = 0.30
var current_phase: int = 1
var transition_locked: bool = false

# =========================
# ATTACK WINDOW CONTROL
# =========================
var attack_can_damage: bool = false
var attack_has_hit: bool = false

var cardinal_direction: Vector2 = Vector2.RIGHT
var direction: Vector2 = Vector2.ZERO
var player: Player
var invulnerable: bool = false
var player_in_range: bool = false
var is_parried: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var player_detector: Area2D = $PlayerDetector

var _hitbox_base_position: Vector2
var _hurtbox_base_position: Vector2

func _ready() -> void:
	add_to_group("enemies")
	player = PlayerManager.player

	if max_hp <= 0:
		max_hp = hp

	hitbox.damaged.connect(_take_damage)

	if player_detector != null:
		if not player_detector.body_entered.is_connected(_on_player_detector_body_entered):
			player_detector.body_entered.connect(_on_player_detector_body_entered)
		if not player_detector.body_exited.is_connected(_on_player_detector_body_exited):
			player_detector.body_exited.connect(_on_player_detector_body_exited)

	if hitbox:
		_hitbox_base_position = hitbox.position
	if hurtbox:
		_hurtbox_base_position = hurtbox.position

	_apply_box_facing()

	# Hitbox receives damage, so it stays active.
	if hitbox:
		hitbox.monitoring = true

	# Hurtbox deals damage, so it starts inactive.
	if hurtbox:
		hurtbox.monitoring = false

	state_machine.Initialize(self)

	if player != null:
		last_player_hp = player.hp
		last_player_y = player.global_position.y

func _physics_process(delta: float) -> void:
	if player == null:
		player = PlayerManager.player

	var previous_position := global_position

	_update_behavior_memory(delta)
	_apply_gravity(delta)
	move_and_slide()
	_prevent_player_push(previous_position)

func _update_behavior_memory(delta: float) -> void:
	_decay_memory(delta)
	_tick_cooldowns(delta)

	if player == null:
		return

	var dist: float = abs(player.global_position.x - global_position.x)
	last_seen_distance = dist

	if dist <= close_range_threshold:
		close_range_time += delta
	else:
		close_range_time = max(close_range_time - delta * 0.5, 0.0)

	if dist >= far_range_threshold:
		far_range_time += delta
	else:
		far_range_time = max(far_range_time - delta * 0.5, 0.0)

	var current_player_state = player.state_machine.current_state
	if current_player_state != null:
		var state_name := String(current_player_state.name).to_lower()

		if state_name.contains("dash"):
			recent_dash_score += 2.4 * delta

		if state_name.contains("parry"):
			recent_parry_score += 2.7 * delta

		if state_name.contains("heal"):
			recent_heal_score += 4.5 * delta

		if state_name.contains("jump") or state_name.contains("fall") or state_name.contains("slam"):
			recent_jump_score += 1.5 * delta

	if dist <= close_range_threshold:
		recent_greedy_score += 0.9 * delta

	_check_phase_progression()

func _decay_memory(delta: float) -> void:
	recent_dash_score = max(recent_dash_score - memory_decay_per_second * delta, 0.0)
	recent_parry_score = max(recent_parry_score - memory_decay_per_second * delta, 0.0)
	recent_heal_score = max(recent_heal_score - memory_decay_per_second * delta, 0.0)
	recent_jump_score = max(recent_jump_score - memory_decay_per_second * delta, 0.0)
	recent_greedy_score = max(recent_greedy_score - memory_decay_per_second * delta, 0.0)

func _tick_cooldowns(delta: float) -> void:
	normal_attack_cd_timer = max(normal_attack_cd_timer - delta, 0.0)
	heavy_attack_cd_timer = max(heavy_attack_cd_timer - delta, 0.0)
	stomp_attack_cd_timer = max(stomp_attack_cd_timer - delta, 0.0)
	feint_cd_timer = max(feint_cd_timer - delta, 0.0)
	punish_attack_cd_timer = max(punish_attack_cd_timer - delta, 0.0)

func _check_phase_progression() -> void:
	if not enable_phases or max_hp <= 0:
		return

	var hp_ratio := float(hp) / float(max_hp)

	if current_phase == 1 and hp_ratio <= phase_two_threshold:
		current_phase = 2
	elif current_phase == 2 and hp_ratio <= phase_three_threshold:
		current_phase = 3

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		if velocity.y > 0:
			velocity.y = 0

func _prevent_player_push(previous_position: Vector2) -> void:
	var collided_with_player := false

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider is Player:
			collided_with_player = true
			break

	if collided_with_player:
		global_position.x = previous_position.x
		velocity.x = 0

		if global_position.y < previous_position.y:
			global_position.y = previous_position.y
			if velocity.y < 0:
				velocity.y = 0

func setDirection(_new_direction: Vector2) -> bool:
	direction = Vector2(_new_direction.x, 0)

	if direction.x == 0:
		return false

	var new_dir := Vector2.RIGHT if direction.x > 0 else Vector2.LEFT

	if new_dir == cardinal_direction:
		return false

	cardinal_direction = new_dir
	directionChanged.emit(new_dir)

	sprite.scale.x = 1 if cardinal_direction == Vector2.LEFT else -1
	_apply_box_facing()

	return true

func _apply_box_facing() -> void:
	var facing_sign := 1.0 if cardinal_direction == Vector2.RIGHT else -1.0

	if hitbox:
		hitbox.position.x = abs(_hitbox_base_position.x) * facing_sign
		hitbox.position.y = _hitbox_base_position.y

	if hurtbox:
		hurtbox.position.x = abs(_hurtbox_base_position.x) * facing_sign
		hurtbox.position.y = _hurtbox_base_position.y

func updateAnimation(state: String) -> void:
	if sprite.sprite_frames == null:
		print("No SpriteFrames assigned")
		return

	if not sprite.sprite_frames.has_animation(state):
		print("Animation missing: ", state)
		return

	if sprite.animation != state:
		sprite.play(state)
	elif not sprite.is_playing():
		sprite.play(state)

func _take_damage(hurtbox: Hurtbox) -> void:
	if invulnerable:
		return

	if player != null and player.has_method("register_behavior_tracked_enemy"):
		player.register_behavior_tracked_enemy(self)

	hp -= hurtbox.damage
	print("takeDamage : ", hurtbox.damage)

	if hp > 0:
		enemyDamaged.emit(hurtbox)
	else:
		enemyDestroyed.emit(hurtbox)

func _on_player_detector_body_entered(body: Node) -> void:
	if body is Player:
		player = body
		player_in_range = true
		print("player entered detection")

func _on_player_detector_body_exited(body: Node) -> void:
	if body is Player:
		player_in_range = false
		print("player exited detection")

func on_parried() -> void:
	is_parried = true
	recent_parry_score += 2.0
	reset_attack_window()
	print(name, " WAS PARRIED")

func can_use_normal_attack() -> bool:
	return normal_attack_cd_timer <= 0.0

func can_use_heavy_attack() -> bool:
	return heavy_attack_cd_timer <= 0.0

func can_use_stomp_attack() -> bool:
	return stomp_attack_cd_timer <= 0.0

func can_use_feint() -> bool:
	return feint_cd_timer <= 0.0

func can_use_punish_attack() -> bool:
	return punish_attack_cd_timer <= 0.0

func mark_attack_used(attack_name: String) -> void:
	last_attack_used = attack_name

	match attack_name:
		"normal":
			normal_attack_cd_timer = normal_attack_cooldown
		"heavy":
			heavy_attack_cd_timer = heavy_attack_cooldown
		"stomp":
			stomp_attack_cd_timer = stomp_attack_cooldown
		"feint":
			feint_cd_timer = feint_cooldown
		"punish":
			punish_attack_cd_timer = punish_attack_cooldown

func wants_to_punish_heal() -> bool:
	return recent_heal_score >= 0.25

func expects_parry() -> bool:
	return recent_parry_score >= 0.45

func expects_dash() -> bool:
	return recent_dash_score >= 0.45

func expects_jump_escape() -> bool:
	return recent_jump_score >= 0.45

func player_is_greedy() -> bool:
	return recent_greedy_score >= 0.6

func should_transition_phase() -> bool:
	if not enable_phases:
		return false
	if transition_locked:
		return false
	return false

func should_do_punish_followup() -> bool:
	var chance := punish_followup_chance_phase_1

	match current_phase:
		2:
			chance = punish_followup_chance_phase_2
		3:
			chance = punish_followup_chance_phase_3

	if player_is_greedy():
		chance += 0.20

	return randf() < chance

# =========================
# ATTACK WINDOW HELPERS
# =========================

func begin_attack_window() -> void:
	attack_can_damage = true
	attack_has_hit = false

	if hurtbox:
		hurtbox.monitoring = true

func end_attack_window() -> void:
	attack_can_damage = false

	if hurtbox:
		hurtbox.monitoring = false

func reset_attack_window() -> void:
	attack_can_damage = false
	attack_has_hit = false

	if hurtbox:
		hurtbox.monitoring = false

func mark_attack_hit() -> void:
	attack_has_hit = true
