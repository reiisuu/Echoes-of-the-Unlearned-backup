class_name State_Attack
extends State

var isAttacking: bool = false

@export var light_attack_sound: AudioStream
@export_range(1, 20, 0.5) var decelerate_speed: float = 8.0
@export var attack_lunge_speed: float = 120.0
@export var hurtbox_start_time: float = 0.05
@export var hurtbox_end_time: float = 0.15
@export var air_attack_freeze_time: float = 0.12

@export var light_attack_cooldown: float = 0.25
@export var max_consecutive_attacks: int = 6
@export var combo_reset_time: float = 0.9
@export var attack_limit_cooldown: float = 1.5

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var run: State = $"../Run"
@onready var jump: State = $"../Jump"
@onready var fall: State = $"../Fall"
@onready var sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var audio: AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"
@onready var hurtbox: Hurtbox = %LightAttackHurtbox
@onready var parry: State = $"../Parry"

var is_air_stalling: bool = false
var air_stall_timer: float = 0.0
var blocked_by_limit: bool = false
var cooldown_timer: float = 0.0

func Enter() -> void:
	player.register_behavior_light_attack()
	isAttacking = false
	is_air_stalling = false
	air_stall_timer = 0.0
	blocked_by_limit = false
	cooldown_timer = light_attack_cooldown
	hurtbox.monitoring = false

	var now := Time.get_ticks_msec() / 1000.0

	if not player.has_meta("light_attack_chain_count"):
		player.set_meta("light_attack_chain_count", 0)

	if not player.has_meta("light_attack_last_time"):
		player.set_meta("light_attack_last_time", -9999.0)

	if not player.has_meta("light_attack_cooldown_until"):
		player.set_meta("light_attack_cooldown_until", 0.0)

	var chain_count: int = int(player.get_meta("light_attack_chain_count"))
	var last_time: float = float(player.get_meta("light_attack_last_time"))
	var cooldown_until: float = float(player.get_meta("light_attack_cooldown_until"))

	if now < cooldown_until:
		blocked_by_limit = true
		player.velocity.x = 0.0
		player.updateAnimation("idle")
		state_machine.ChangeState(idle)
		return

	if now - last_time > combo_reset_time:
		chain_count = 0

	chain_count += 1

	if chain_count > max_consecutive_attacks:
		player.set_meta("light_attack_chain_count", 0)
		player.set_meta("light_attack_last_time", now)
		player.set_meta("light_attack_cooldown_until", now + attack_limit_cooldown)

		blocked_by_limit = true
		player.velocity.x = 0.0
		player.updateAnimation("idle")
		state_machine.ChangeState(idle)
		return

	player.set_meta("light_attack_chain_count", chain_count)
	player.set_meta("light_attack_last_time", now)

	isAttacking = true

	player.setDirection()

	var attack_direction := player.get_facing_direction()

	if player.is_on_floor():
		player.velocity.x = attack_direction * attack_lunge_speed
		player.velocity.y = 0.0
	else:
		player.velocity = Vector2.ZERO
		is_air_stalling = true
		air_stall_timer = air_attack_freeze_time

	player.updateAnimation("light_attack")
	player.play_effect("light_attack_effect")

	if not sprite.animation_finished.is_connected(endAttack):
		sprite.animation_finished.connect(endAttack)

	if light_attack_sound != null:
		audio.stream = light_attack_sound
		audio.pitch_scale = randf_range(0.9, 1.1)
		audio.play()

	_activate_hurtbox()

func Exit() -> void:
	if sprite.animation_finished.is_connected(endAttack):
		sprite.animation_finished.disconnect(endAttack)

	isAttacking = false
	is_air_stalling = false
	air_stall_timer = 0.0
	blocked_by_limit = false
	cooldown_timer = 0.0
	hurtbox.monitoring = false
	
	player.stop_effect()

func Process(delta: float) -> State:
	if blocked_by_limit:
		return idle

	if is_air_stalling:
		air_stall_timer -= delta
		player.velocity = Vector2.ZERO

		if air_stall_timer <= 0.0:
			is_air_stalling = false
			player.velocity.x = player.get_facing_direction() * attack_lunge_speed * 0.6
		return null

	if not isAttacking:
		cooldown_timer -= delta
		if cooldown_timer > 0.0:
			return null

		if not player.is_on_floor():
			if player.velocity.y < 0.0:
				return jump
			return fall

		if player.direction == Vector2.ZERO:
			return idle
		elif player.isRunning:
			return run
		else:
			return walk

	return null

func Physics(delta: float) -> State:
	if blocked_by_limit:
		player.move_and_slide()
		return null

	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, decelerate_speed * 100.0 * delta)
		player.velocity.y = 0.0
	else:
		if not is_air_stalling:
			player.apply_air_gravity(delta)
			player.velocity.x = move_toward(player.velocity.x, 0.0, decelerate_speed * 70.0 * delta)

	player.move_and_slide()
	return null

func HandleInput(event: InputEvent) -> State:
	if event.is_action_pressed("parry") and not event.is_echo():
		return parry

	if event.is_action_pressed("stance") and not event.is_echo():
		player.isRunning = !player.isRunning

	return null

func endAttack() -> void:
	isAttacking = false

func _activate_hurtbox() -> void:
	_enable_hurtbox()

func _enable_hurtbox() -> void:
	await get_tree().create_timer(hurtbox_start_time).timeout

	if not isAttacking:
		return

	hurtbox.monitoring = true

	await get_tree().create_timer(hurtbox_end_time - hurtbox_start_time).timeout
	hurtbox.monitoring = false
