class_name EnemyStateChase
extends EnemyState

@export var anim_name: String = "walk"
@export var chase_speed: float = 55.0
@export var pressure_speed_multiplier_phase_2: float = 1.15
@export var pressure_speed_multiplier_phase_3: float = 1.28

@export var attack_range: float = 42.0
@export var attack_state: EnemyState

@export var heavy_attack_range: float = 82.0
@export var heavy_attack_state: EnemyState

@export var stomp_attack_range: float = 125.0
@export var stomp_attack_state: EnemyState

@export var feint_attack_range: float = 58.0
@export var feint_attack_state: EnemyState

@export var lost_player_state: EnemyState
@export var phase_transition_state: EnemyState

func Enter() -> void:
	enemy.updateAnimation(anim_name)
	print("ENTER CHASE")

func Exit() -> void:
	enemy.velocity = Vector2.ZERO

func process(_delta: float) -> EnemyState:
	if enemy.player == null:
		return lost_player_state

	if not enemy.player_in_range:
		return lost_player_state

	# Optional phase transition hook if you wire it later manually
	if enemy.should_transition_phase() and phase_transition_state != null:
		enemy.transition_locked = true
		return phase_transition_state

	var dx := enemy.player.global_position.x - enemy.global_position.x
	var dist: float = abs(dx)

	# 1. Highest priority: punish healing immediately
	if enemy.wants_to_punish_heal():
		if dist <= attack_range and attack_state != null and enemy.can_use_normal_attack():
			enemy.mark_attack_used("attack")
			return attack_state

		if dist <= heavy_attack_range and heavy_attack_state != null and enemy.can_use_heavy_attack():
			enemy.mark_attack_used("heavy")
			return heavy_attack_state

		if dist <= stomp_attack_range and stomp_attack_state != null and enemy.can_use_stomp_attack():
			enemy.mark_attack_used("stomp")
			return stomp_attack_state

	# 2. Parry-heavy player: prefer feint then delayed punish
	if enemy.expects_parry():
		if dist <= feint_attack_range and feint_attack_state != null and enemy.can_use_feint():
			enemy.mark_attack_used("feint")
			return feint_attack_state

		if dist <= heavy_attack_range and heavy_attack_state != null and enemy.can_use_heavy_attack():
			enemy.mark_attack_used("heavy")
			return heavy_attack_state

	# 3. Dash-heavy player: use delayed/heavier moves more often
	if enemy.expects_dash():
		if dist <= heavy_attack_range and heavy_attack_state != null and enemy.can_use_heavy_attack():
			enemy.mark_attack_used("heavy")
			return heavy_attack_state

		if dist <= stomp_attack_range and stomp_attack_state != null and enemy.can_use_stomp_attack():
			enemy.mark_attack_used("stomp")
			return stomp_attack_state

	# 4. Jump-happy / keeps leaving ground
	if enemy.expects_jump_escape():
		if dist <= stomp_attack_range and stomp_attack_state != null and enemy.can_use_stomp_attack():
			enemy.mark_attack_used("stomp")
			return stomp_attack_state

	# 5. Greedy close-range player
	if dist <= attack_range:
		if enemy.player_is_greedy() and enemy.expects_parry() and feint_attack_state != null and enemy.can_use_feint():
			enemy.mark_attack_used("feint")
			return feint_attack_state

		if attack_state != null and enemy.can_use_normal_attack():
			enemy.mark_attack_used("normal")
			return attack_state

	# 6. Mid range mix
	if dist <= feint_attack_range:
		if enemy.expects_parry() and feint_attack_state != null and enemy.can_use_feint():
			enemy.mark_attack_used("feint")
			return feint_attack_state

		if attack_state != null and enemy.can_use_normal_attack():
			enemy.mark_attack_used("normal")
			return attack_state

	if dist <= heavy_attack_range:
		if heavy_attack_state != null and enemy.can_use_heavy_attack():
			enemy.mark_attack_used("heavy")
			return heavy_attack_state

	if dist <= stomp_attack_range:
		if stomp_attack_state != null and enemy.can_use_stomp_attack():
			enemy.mark_attack_used("stomp")
			return stomp_attack_state

	return null

func physics(_delta: float) -> EnemyState:
	if enemy.player == null:
		enemy.velocity = Vector2.ZERO
		return null

	var dx := enemy.player.global_position.x - enemy.global_position.x
	var dist: float = abs(dx)
	var dir_x: float = sign(dx)

	if dir_x != 0:
		enemy.setDirection(Vector2(dir_x, 0))

	var speed := chase_speed

	if enemy.current_phase == 2:
		speed *= pressure_speed_multiplier_phase_2
	elif enemy.current_phase == 3:
		speed *= pressure_speed_multiplier_phase_3

	# Smarter spacing instead of just freezing
	# Very close: sometimes hold pressure, sometimes micro-step back
	if dist <= attack_range * 0.75:
		if enemy.expects_parry():
			enemy.velocity.x = -dir_x * speed * 0.20
		else:
			enemy.velocity.x = dir_x * speed * 0.20
		return null

	# In ideal close-mid range: keep pressure unless ready to fire attack in process()
	if dist <= heavy_attack_range:
		enemy.velocity.x = dir_x * speed * 0.75
		return null

	# Farther away: close distance aggressively
	if dist > heavy_attack_range:
		enemy.velocity.x = dir_x * speed
		return null

	return null
