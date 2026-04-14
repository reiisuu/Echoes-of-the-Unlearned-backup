class_name BossAIContext
extends Node

@export var history_limit: int = 6

var boss: Boss = null
var player: Player = null
var recent_actions: Array[String] = []

func _ready() -> void:
	boss = get_parent() as Boss
	if boss != null:
		player = boss.player

func add_action(action_name: String) -> void:
	if action_name.is_empty():
		return

	recent_actions.append(action_name)

	while recent_actions.size() > history_limit:
		recent_actions.pop_front()

func get_payload() -> Dictionary:
	if boss == null:
		return {}

	if player == null or not is_instance_valid(player):
		player = boss.player

	var player_behavior := {}
	if player != null and player.has_node("PlayerBehaviorLogger"):
		var logger = player.get_node("PlayerBehaviorLogger")
		if logger != null and logger.has_method("get_behavior_snapshot"):
			player_behavior = logger.get_behavior_snapshot()

	var player_state_name := "none"
	if player != null and player.get("state_machine") != null:
		var sm = player.get("state_machine")
		if sm != null and sm.current_state != null:
			player_state_name = String(sm.current_state.name)

	var boss_state_name := "none"
	if boss.state_machine != null and boss.state_machine.current_state != null:
		boss_state_name = String(boss.state_machine.current_state.name)

	var dist := 99999.0
	if player != null:
		dist = boss.global_position.distance_to(player.global_position)

	var player_hp := 0
	var player_max_hp := 0
	var player_is_parrying := false
	var player_is_healing := false
	var player_is_attacking := false
	var player_is_charging_attack := false
	var player_parry_successful := false

	if player != null:
		if "hp" in player:
			player_hp = player.hp
		if "maxHp" in player:
			player_max_hp = player.maxHp
		if player.get("is_parrying") != null:
			player_is_parrying = player.get("is_parrying")
		if player.get("is_healing") != null:
			player_is_healing = player.get("is_healing")
		if player.get("is_attacking") != null:
			player_is_attacking = player.get("is_attacking")
		if player.get("is_charging_attack") != null:
			player_is_charging_attack = player.get("is_charging_attack")
		if player.get("parry_successful") != null:
			player_parry_successful = player.get("parry_successful")

	return {
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"player_behavior": player_behavior,
		"player_state": {
			"hp": player_hp,
			"max_hp": player_max_hp,
			"state": player_state_name,
			"distance_to_boss": dist,
			"is_parrying": player_is_parrying,
			"is_healing": player_is_healing,
			"is_attacking": player_is_attacking,
			"is_charging_attack": player_is_charging_attack,
			"parry_successful": player_parry_successful
		},
		"boss_state": {
			"hp": boss.hp,
			"max_hp": boss.max_hp,
			"state": boss_state_name,
			"phase": boss.current_phase,
			"in_phase_2": boss.in_phase_2,
			"distance_to_player": dist,
			"player_in_range": boss.player_in_range,
			"last_action": boss.last_attack_used,
			"can_normal": boss.can_use_attack("normal"),
			"can_heavy": boss.can_use_attack("heavy"),
			"can_stomp": boss.can_use_attack("stomp"),
			"can_punish": boss.can_use_attack("punish"),
			"can_backstep": boss.can_use_attack("backstep"),
			"can_feint": boss.can_use_feint(),
			"can_phase_transition": boss.can_use_phase_transition()
		},
		"boss_recent_actions": recent_actions.duplicate()
	}
