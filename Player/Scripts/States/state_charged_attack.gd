class_name State_ChargedAttack
extends State

@export var release_duration: float = 0.30
@export var hitbox_start_time: float = 0.0
@export var hitbox_end_time: float = 0.18

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var run: State = $"../Run"
@onready var fall: State = $"../Fall"
@onready var charged_attack_effect: AnimatedSprite2D = $"../../AnimatedSprite2D/ChargedAttackEffect"
@onready var charged_hurtbox: Hurtbox = %ChargedAttackHurtbox

var release_time: float = 0.0
var released: bool = false
var hitbox_enabled: bool = false
var hitbox_disabled: bool = false
var already_hit: Array[Area2D] = []

func Enter() -> void:
	player.register_behavior_heavy_attack()
	player.is_charged_attacking = true
	player.velocity.x = 0.0

	release_time = 0.0
	released = false
	hitbox_enabled = false
	hitbox_disabled = false
	already_hit.clear()

	player.disable_charged_attack_hitbox()

	if charged_attack_effect:
		charged_attack_effect.visible = false
		charged_attack_effect.stop()

	player.updateAnimation("idle") # change to "charge" if you have one

func Exit() -> void:
	player.is_charged_attacking = false
	player.disable_charged_attack_hitbox()
	already_hit.clear()

	if charged_attack_effect:
		charged_attack_effect.stop()
		charged_attack_effect.visible = false

func Process(delta: float) -> State:
	if not released:
		player.velocity.x = 0.0
		player.disable_charged_attack_hitbox()

		if not Input.is_action_pressed("charged_attack"):
			_release_attack()

		return null

	release_time += delta

	if not hitbox_enabled and release_time >= hitbox_start_time:
		hitbox_enabled = true
		player.enable_charged_attack_hitbox()
		_force_damage_check()

	if hitbox_enabled and not hitbox_disabled:
		_force_damage_check()

	if hitbox_enabled and not hitbox_disabled and release_time >= hitbox_end_time:
		hitbox_disabled = true
		player.disable_charged_attack_hitbox()

	if release_time >= release_duration:
		player.disable_charged_attack_hitbox()

		if not player.is_on_floor():
			return fall
		if player.direction == Vector2.ZERO:
			return idle
		if player.isRunning:
			return run
		return walk

	return null

func Physics(_delta: float) -> State:
	player.velocity.x = 0.0
	player.move_and_slide()
	return null

func _release_attack() -> void:
	released = true
	release_time = 0.0
	hitbox_enabled = false
	hitbox_disabled = false
	already_hit.clear()

	player.updateAnimation("charged_attack")

	if charged_attack_effect:
		charged_attack_effect.visible = true
		charged_attack_effect.play()

	player.disable_charged_attack_hitbox()

func _force_damage_check() -> void:
	if charged_hurtbox == null:
		return

	for area in charged_hurtbox.get_overlapping_areas():
		if area is Hitbox and not already_hit.has(area):
			already_hit.append(area)
			area.takeDamage(charged_hurtbox)
