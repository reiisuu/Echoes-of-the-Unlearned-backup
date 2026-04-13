class_name PlayerBehaviorLogger
extends Node

@export var close_range_threshold: float = 55.0
@export var far_range_threshold: float = 135.0
@export var memory_decay_per_second: float = 0.8
@export var debug_print_enabled: bool = true
@export var debug_print_interval: float = 1.0
@export var auto_find_enemy_if_missing: bool = true

@export var recent_action_window: float = 2.0
@export var greedy_score_threshold: float = 0.6
@export var dash_score_threshold: float = 0.45
@export var parry_score_threshold: float = 0.45
@export var heal_score_threshold: float = 0.25
@export var jump_score_threshold: float = 0.45

var dash_score: float = 0.0
var parry_score: float = 0.0
var heal_score: float = 0.0
var jump_score: float = 0.0
var greedy_score: float = 0.0

var light_attack_score: float = 0.0
var heavy_attack_score: float = 0.0
var slam_attack_score: float = 0.0

var close_range_time: float = 0.0
var far_range_time: float = 0.0

var attack_chain_count: int = 0
var highest_attack_chain: int = 0

var dash_count: int = 0
var parry_count: int = 0
var heal_count: int = 0
var jump_count: int = 0

var light_attack_count: int = 0
var heavy_attack_count: int = 0
var slam_attack_count: int = 0
var total_attack_count: int = 0

var last_attack_time: float = -999.0
var last_dash_time: float = -999.0
var last_parry_time: float = -999.0
var last_heal_time: float = -999.0
var last_jump_time: float = -999.0

var last_light_attack_time: float = -999.0
var last_heavy_attack_time: float = -999.0
var last_slam_attack_time: float = -999.0

var tracked_enemy: Enemy = null
var player: Player = null
var debug_timer: float = 0.0

func _ready() -> void:
	player = get_parent() as Player

	if player == null:
		push_warning("PlayerBehaviorLogger parent is not a Player")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if auto_find_enemy_if_missing and (tracked_enemy == null or not is_instance_valid(tracked_enemy)):
		_try_auto_track_enemy()

	_decay_scores(delta)
	_track_player_state(delta)
	_track_distance_to_enemy(delta)
	_debug_print(delta)

func _try_auto_track_enemy() -> void:
	if tracked_enemy != null and is_instance_valid(tracked_enemy):
		return

	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		tracked_enemy = null
		return

	var nearest_enemy: Enemy = null
	var nearest_dist := INF

	for node in enemies:
		if node is Enemy and is_instance_valid(node):
			var dist := player.global_position.distance_to(node.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_enemy = node

	tracked_enemy = nearest_enemy

func _decay_scores(delta: float) -> void:
	dash_score = max(dash_score - memory_decay_per_second * delta, 0.0)
	parry_score = max(parry_score - memory_decay_per_second * delta, 0.0)
	heal_score = max(heal_score - memory_decay_per_second * delta, 0.0)
	jump_score = max(jump_score - memory_decay_per_second * delta, 0.0)
	greedy_score = max(greedy_score - memory_decay_per_second * delta, 0.0)

	light_attack_score = max(light_attack_score - memory_decay_per_second * delta, 0.0)
	heavy_attack_score = max(heavy_attack_score - memory_decay_per_second * delta, 0.0)
	slam_attack_score = max(slam_attack_score - memory_decay_per_second * delta, 0.0)

func _track_player_state(delta: float) -> void:
	if player.state_machine == null or player.state_machine.current_state == null:
		return

	var state_name := String(player.state_machine.current_state.name).to_lower()
	var now := _now()

	if state_name.contains("dash"):
		dash_score += 2.4 * delta
		if now - last_dash_time > 0.25:
			dash_count += 1
			last_dash_time = now

	if state_name.contains("parry"):
		parry_score += 2.7 * delta
		if now - last_parry_time > 0.25:
			parry_count += 1
			last_parry_time = now

	if state_name.contains("heal"):
		heal_score += 4.5 * delta
		if now - last_heal_time > 0.25:
			heal_count += 1
			last_heal_time = now

	if state_name.contains("jump") or state_name.contains("fall") or state_name.contains("slam"):
		jump_score += 1.5 * delta
		if state_name.contains("jump") and now - last_jump_time > 0.25:
			jump_count += 1
			last_jump_time = now

func _track_distance_to_enemy(delta: float) -> void:
	if tracked_enemy == null or not is_instance_valid(tracked_enemy) or player == null:
		return

	var dist := player.global_position.distance_to(tracked_enemy.global_position)

	if dist <= close_range_threshold:
		close_range_time += delta
		greedy_score += 0.9 * delta
	else:
		close_range_time = max(close_range_time - delta * 0.5, 0.0)

	if dist >= far_range_threshold:
		far_range_time += delta
	else:
		far_range_time = max(far_range_time - delta * 0.5, 0.0)

func _debug_print(delta: float) -> void:
	if not debug_print_enabled:
		return

	debug_timer += delta
	if debug_timer < debug_print_interval:
		return

	debug_timer = 0.0

	var state_name := "none"
	if player != null and player.state_machine != null and player.state_machine.current_state != null:
		state_name = str(player.state_machine.current_state.name)

	var enemy_name := "none"
	if tracked_enemy != null and is_instance_valid(tracked_enemy):
		enemy_name = tracked_enemy.name

	print("\n================ PLAYER BEHAVIOR ================")
	print("State: ", state_name, " | Enemy: ", enemy_name)

	print("--- SCORES ---")
	print("Dash: ", snapped(dash_score, 0.01),
		  " | Parry: ", snapped(parry_score, 0.01),
		  " | Heal: ", snapped(heal_score, 0.01),
		  " | Jump: ", snapped(jump_score, 0.01),
		  " | Greedy: ", snapped(greedy_score, 0.01))

	print("--- ATTACK SCORES ---")
	print("Light: ", snapped(light_attack_score, 0.01),
		  " | Heavy: ", snapped(heavy_attack_score, 0.01),
		  " | Slam: ", snapped(slam_attack_score, 0.01))

	print("--- RANGE ---")
	print("Close Time: ", snapped(close_range_time, 0.01),
		  " | Far Time: ", snapped(far_range_time, 0.01))

	print("--- COMBAT ---")
	print("Chain: ", attack_chain_count,
		  " | Max Chain: ", highest_attack_chain,
		  " | Total Attacks: ", total_attack_count)

	print("--- ATTACK COUNTS ---")
	print("Light: ", light_attack_count,
		  " | Heavy: ", heavy_attack_count,
		  " | Slam: ", slam_attack_count)

	print("--- ACTION COUNTS ---")
	print("Dash: ", dash_count,
		  " | Parry: ", parry_count,
		  " | Heal: ", heal_count,
		  " | Jump: ", jump_count)

	print("--- TIMERS ---")
	print("Any Atk: ", snapped(time_since_last_attack(), 0.01),
		  " | Light: ", snapped(time_since_last_light_attack(), 0.01),
		  " | Heavy: ", snapped(time_since_last_heavy_attack(), 0.01),
		  " | Slam: ", snapped(time_since_last_slam_attack(), 0.01))

	print("================================================\n")

func register_light_attack() -> void:
	var now := _now()

	total_attack_count += 1
	light_attack_count += 1
	light_attack_score += 2.0

	_register_attack_chain(now)
	last_light_attack_time = now

func register_heavy_attack() -> void:
	var now := _now()

	total_attack_count += 1
	heavy_attack_count += 1
	heavy_attack_score += 2.4

	_register_attack_chain(now)
	last_heavy_attack_time = now

func register_slam_attack() -> void:
	var now := _now()

	total_attack_count += 1
	slam_attack_count += 1
	slam_attack_score += 2.8
	jump_score += 0.5

	_register_attack_chain(now)
	last_slam_attack_time = now

func _register_attack_chain(now: float) -> void:
	if now - last_attack_time <= 0.7:
		attack_chain_count += 1
	else:
		attack_chain_count = 1

	last_attack_time = now
	highest_attack_chain = max(highest_attack_chain, attack_chain_count)

	if attack_chain_count >= 3:
		greedy_score += 0.5

func register_dash() -> void:
	dash_count += 1
	last_dash_time = _now()

func register_parry() -> void:
	parry_count += 1
	last_parry_time = _now()

func register_heal() -> void:
	heal_count += 1
	last_heal_time = _now()

func register_jump() -> void:
	jump_count += 1
	last_jump_time = _now()

func set_tracked_enemy(new_enemy: Enemy) -> void:
	tracked_enemy = new_enemy

func get_behavior_snapshot() -> Dictionary:
	return {
		"dash_score": dash_score,
		"parry_score": parry_score,
		"heal_score": heal_score,
		"jump_score": jump_score,
		"greedy_score": greedy_score,

		"light_attack_score": light_attack_score,
		"heavy_attack_score": heavy_attack_score,
		"slam_attack_score": slam_attack_score,

		"close_range_time": close_range_time,
		"far_range_time": far_range_time,

		"attack_chain_count": attack_chain_count,
		"highest_attack_chain": highest_attack_chain,

		"dash_count": dash_count,
		"parry_count": parry_count,
		"heal_count": heal_count,
		"jump_count": jump_count,

		"light_attack_count": light_attack_count,
		"heavy_attack_count": heavy_attack_count,
		"slam_attack_count": slam_attack_count,
		"total_attack_count": total_attack_count,

		"time_since_last_attack": time_since_last_attack(),
		"time_since_last_light_attack": time_since_last_light_attack(),
		"time_since_last_heavy_attack": time_since_last_heavy_attack(),
		"time_since_last_slam_attack": time_since_last_slam_attack(),
		"time_since_last_dash": time_since_last_dash(),
		"time_since_last_parry": time_since_last_parry(),
		"time_since_last_heal": time_since_last_heal(),
		"time_since_last_jump": time_since_last_jump()
	}

func prefers_light_attack() -> bool:
	return light_attack_score > heavy_attack_score and light_attack_score > slam_attack_score

func prefers_heavy_attack() -> bool:
	return heavy_attack_score > light_attack_score and heavy_attack_score > slam_attack_score

func prefers_slam_attack() -> bool:
	return slam_attack_score > light_attack_score and slam_attack_score > heavy_attack_score

func is_dash_heavy() -> bool:
	return dash_score >= dash_score_threshold

func is_parry_heavy() -> bool:
	return parry_score >= parry_score_threshold

func is_heal_happy() -> bool:
	return heal_score >= heal_score_threshold

func is_jumpy() -> bool:
	return jump_score >= jump_score_threshold

func is_greedy() -> bool:
	return greedy_score >= greedy_score_threshold

func attacked_recently() -> bool:
	return time_since_last_attack() <= recent_action_window

func light_attacked_recently() -> bool:
	return time_since_last_light_attack() <= recent_action_window

func heavy_attacked_recently() -> bool:
	return time_since_last_heavy_attack() <= recent_action_window

func slam_attacked_recently() -> bool:
	return time_since_last_slam_attack() <= recent_action_window

func healed_recently() -> bool:
	return time_since_last_heal() <= recent_action_window

func dashed_recently() -> bool:
	return time_since_last_dash() <= recent_action_window

func parried_recently() -> bool:
	return time_since_last_parry() <= recent_action_window

func jumped_recently() -> bool:
	return time_since_last_jump() <= recent_action_window

func time_since_last_attack() -> float:
	return _now() - last_attack_time

func time_since_last_light_attack() -> float:
	return _now() - last_light_attack_time

func time_since_last_heavy_attack() -> float:
	return _now() - last_heavy_attack_time

func time_since_last_slam_attack() -> float:
	return _now() - last_slam_attack_time

func time_since_last_dash() -> float:
	return _now() - last_dash_time

func time_since_last_parry() -> float:
	return _now() - last_parry_time

func time_since_last_heal() -> float:
	return _now() - last_heal_time

func time_since_last_jump() -> float:
	return _now() - last_jump_time

func reset_behavior_memory() -> void:
	dash_score = 0.0
	parry_score = 0.0
	heal_score = 0.0
	jump_score = 0.0
	greedy_score = 0.0

	light_attack_score = 0.0
	heavy_attack_score = 0.0
	slam_attack_score = 0.0

	close_range_time = 0.0
	far_range_time = 0.0
	attack_chain_count = 0

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
