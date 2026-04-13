class_name Player
extends CharacterBody2D

signal directionChanged(new_direction: Vector2)
signal playerDamaged(hurtbox: Hurtbox)

var cardinal_direction: Vector2 = Vector2.RIGHT
var direction: Vector2 = Vector2.ZERO
var isRunning: bool = false

@onready var behavior_logger: PlayerBehaviorLogger = $PlayerBehaviorLogger

@export var move_speed: float = 300.0
@export var run_speed_multiplier: float = 1.5
@export var ground_acceleration: float = 2500.0
@export var ground_deceleration: float = 3000.0
@export var air_acceleration: float = 2000.0

@export var jump_velocity: float = -900.0
@export var gravity: float = 2600.0
@export var fall_gravity: float = 3200.0
@export var max_fall_speed: float = 1000.0
@export var jump_cut_multiplier: float = 0.5

@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12

@export var max_jumps: int = 2
var jumps_left: int = 0
var was_on_floor: bool = false

@export var dash_speed: float = 650.0
@export var dash_time: float = 0.18
@export var dash_cooldown: float = 0.35

var is_parrying: bool = false
var parry_window: float = 0.2
var parry_timer: float = 0.0
var parry_cooldown: float = 0.5
var parry_cd_timer: float = 0.0
var invuln_timer: float = 0.0
var parry_iframes_on_success: float = 0.15
var parry_successful: bool = false

@export var slam_speed: float = 1400.0
@export var slam_damage: int = 2
var is_slamming: bool = false
var has_slammed_in_air: bool = false

# =========================
# HEAL
# =========================
@export var heal_amount: int = 2
@export var heal_cooldown: float = 4.0
var can_heal: bool = true
var is_healing: bool = false

# =========================
# CHARGED ATTACK
# =========================
@export var charged_attack_damage: int = 2
@export var charged_attack_cooldown: float = 1.5
var can_charged_attack: bool = true
var is_charged_attacking: bool = false

# =========================
# ENRAGE
# =========================
@export var enrage_duration: float = 15.0
@export var enrage_damage_multiplier: float = 2.0
@export var enrage_modulate: Color = Color(1.0, 0.45, 0.45, 1.0)
@export var enrage_cooldown: float = 45.0
var can_enrage: bool = true
var enrage_cooldown_timer: float = 0.0
var is_enraged: bool = false
var enrage_timer: float = 0.0
var normal_modulate: Color = Color(1, 1, 1, 1)

@onready var slam_hitbox: Hurtbox = %Slam

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light_attack_effect: AnimatedSprite2D = $AnimatedSprite2D/LightAttackEffect
@onready var dash_effect: AnimatedSprite2D = $AnimatedSprite2D/DashEffect
@onready var slam_effect: AnimatedSprite2D = $AnimatedSprite2D/SlamEffect
@onready var heal_effect: AnimatedSprite2D = $AnimatedSprite2D/HealEffect
@onready var charged_attack_effect: AnimatedSprite2D = $AnimatedSprite2D/ChargedAttackEffect

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hitbox: Hitbox = $Hitbox
@onready var effect_animation: AnimationPlayer = $EffectAnimation
@onready var light_attack_hurt: Hurtbox = %LightAttackHurtbox
@onready var charged_attack_hurtbox: Hurtbox = %ChargedAttackHurtbox

@onready var heal_timer: Timer = $HealTimer
@onready var charged_attack_timer: Timer = $ChargedAttackTimer

@export var invulnerable: bool = false
var hp: int = 20
var maxHp: int = 20

var input_x: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var can_dash: bool = true
var dash_cooldown_timer: float = 0.0

var checkpoint_position: Vector2

func _ready() -> void:
	PlayerManager.player = self
	state_machine.Initialize(self)
	hitbox.damaged.connect(_take_damage)
	checkpoint_position = global_position  # default spawn

	if sprite:
		normal_modulate = sprite.modulate

	_setup_effect(light_attack_effect)
	_setup_effect(dash_effect)
	_setup_effect(slam_effect)
	_setup_effect(heal_effect)

	if slam_hitbox:
		slam_hitbox.monitoring = false

	if charged_attack_hurtbox:
		charged_attack_hurtbox.monitoring = false

	if heal_timer:
		heal_timer.wait_time = heal_cooldown
		heal_timer.one_shot = true
		if not heal_timer.timeout.is_connected(_on_heal_timer_timeout):
			heal_timer.timeout.connect(_on_heal_timer_timeout)

	if charged_attack_timer:
		charged_attack_timer.wait_time = charged_attack_cooldown
		charged_attack_timer.one_shot = true
		if not charged_attack_timer.timeout.is_connected(_on_charged_attack_timer_timeout):
			charged_attack_timer.timeout.connect(_on_charged_attack_timer_timeout)

	jumps_left = max_jumps
	was_on_floor = is_on_floor()
	update_hp(99)

func _process(delta: float) -> void:
	input_x = Input.get_axis("left", "right")
	direction = Vector2(input_x, 0)
	setDirection()
	
	if Input.is_action_just_pressed("ui_accept"): # Enter key by default
		die()

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if invuln_timer > 0.0:
		invuln_timer -= delta
		if invuln_timer <= 0.0:
			invulnerable = false

	if is_enraged:
		enrage_timer -= delta
		if enrage_timer <= 0.0:
			stop_enrage()

	if not can_enrage:
		enrage_cooldown_timer -= delta
		if enrage_cooldown_timer <= 0.0:
			can_enrage = true
			print("ENRAGE READY")

	if not (state_machine.current_state is State_Parry):
		is_parrying = false
		parry_successful = false

func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true

	var on_floor_now := is_on_floor()

	if on_floor_now:
		coyote_timer = coyote_time

		if not was_on_floor:
			jumps_left = max_jumps
			has_slammed_in_air = false
			can_dash = true
			dash_cooldown_timer = 0.0
	else:
		coyote_timer -= delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	was_on_floor = on_floor_now

func _setup_effect(effect: AnimatedSprite2D) -> void:
	if effect == null:
		return

	effect.visible = false
	effect.stop()

	if not effect.animation_finished.is_connected(_on_any_effect_animation_finished.bind(effect)):
		effect.animation_finished.connect(_on_any_effect_animation_finished.bind(effect))

func setDirection() -> bool:
	var new_dir: Vector2 = cardinal_direction

	if direction == Vector2.ZERO:
		return false

	if direction.x < 0:
		new_dir = Vector2.LEFT
	elif direction.x > 0:
		new_dir = Vector2.RIGHT

	if new_dir == cardinal_direction:
		return false

	cardinal_direction = new_dir
	directionChanged.emit(new_dir)
	sprite.flip_h = cardinal_direction == Vector2.LEFT

	update_attack_hitbox_direction()
	update_effect_directions()

	return true

func update_effect_directions() -> void:
	var facing_left := cardinal_direction == Vector2.LEFT

	var offset := 25.0  # adjust per effect

	if light_attack_effect:
		light_attack_effect.position.x = -offset if facing_left else offset

	if dash_effect:
		dash_effect.position.x = -offset if facing_left else offset

	if charged_attack_effect:
		charged_attack_effect.position.x = -offset if facing_left else offset

	if slam_effect:
		slam_effect.position.x = 0

	if heal_effect:
		heal_effect.position.x = 0

func update_attack_hitbox_direction() -> void:
	var light_offset_x := 20.0
	var charged_offset_x := 28.0

	if cardinal_direction == Vector2.LEFT:
		light_attack_hurt.position.x = -light_offset_x - 50
		if charged_attack_hurtbox:
			charged_attack_hurtbox.position.x = -charged_offset_x - 100
	else:
		light_attack_hurt.position.x = light_offset_x
		if charged_attack_hurtbox:
			charged_attack_hurtbox.position.x = charged_offset_x

func updateAnimation(state: String) -> void:
	if sprite.animation != state:
		sprite.play(state)
	elif not sprite.is_playing():
		sprite.play(state)

func get_facing_direction() -> float:
	return -1.0 if cardinal_direction == Vector2.LEFT else 1.0

func get_current_move_speed() -> float:
	return move_speed * run_speed_multiplier if isRunning else move_speed

func apply_air_gravity(delta: float) -> void:
	if velocity.y < 0.0:
		velocity.y += gravity * delta
	else:
		velocity.y += fall_gravity * delta

	velocity.y = min(velocity.y, max_fall_speed)

func apply_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

func apply_ground_movement(delta: float, speed_multiplier: float = 1.0) -> void:
	var target_speed := input_x * move_speed * speed_multiplier

	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, ground_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)

func apply_air_movement(delta: float, speed_multiplier: float = 1.0) -> void:
	var target_speed := input_x * move_speed * speed_multiplier
	velocity.x = move_toward(velocity.x, target_speed, air_acceleration * delta)

func can_ground_jump() -> bool:
	return is_on_floor() or coyote_timer > 0.0

func can_air_jump() -> bool:
	return not can_ground_jump() and jumps_left > 0

func can_jump() -> bool:
	return can_ground_jump() or can_air_jump()

func consume_jump() -> bool:
	if not can_jump():
		return false
		
	register_behavior_jump()

	velocity.y = jump_velocity
	jump_buffer_timer = 0.0

	if can_ground_jump():
		coyote_timer = 0.0
		jumps_left = max(max_jumps - 1, 0)
	else:
		jumps_left -= 1

	return true

func start_slam() -> void:
	is_slamming = true
	has_slammed_in_air = true
	velocity.x = 0.0
	velocity.y = slam_speed

	if slam_hitbox:
		slam_hitbox.damage = get_slam_damage()
		slam_hitbox.set_deferred("monitoring", true)

func end_slam() -> void:
	is_slamming = false

	if slam_hitbox:
		slam_hitbox.set_deferred("monitoring", false)

func start_dash_cooldown() -> void:
	can_dash = false
	dash_cooldown_timer = dash_cooldown

func can_start_heal() -> bool:
	return (
		can_heal
		and not is_healing
		and not is_slamming
		and not is_parrying
		and not is_charged_attacking
		and hp < maxHp
	)

func apply_heal() -> void:
	if not can_start_heal() and not is_healing:
		return

	update_hp(heal_amount)
	can_heal = false

	if heal_timer:
		heal_timer.start()

func can_use_charged_attack() -> bool:
	return (
		can_charged_attack
		and not is_slamming
		and not is_parrying
		and not is_healing
	)

func _on_heal_timer_timeout() -> void:
	can_heal = true

func start_charged_attack_cooldown() -> void:
	can_charged_attack = false

	if charged_attack_timer:
		charged_attack_timer.start()

func _on_charged_attack_timer_timeout() -> void:
	can_charged_attack = true

func enable_charged_attack_hitbox() -> void:
	if charged_attack_hurtbox:
		charged_attack_hurtbox.damage = get_charged_attack_damage()
		charged_attack_hurtbox.set_deferred("monitoring", true)
		print("CHARGED HITBOX ON")

func disable_charged_attack_hitbox() -> void:
	if charged_attack_hurtbox:
		charged_attack_hurtbox.set_deferred("monitoring", false)
		print("CHARGED HITBOX OFF")

func start_enrage() -> void:
	if not can_enrage:
		print("ENRAGE ON COOLDOWN")
		return

	is_enraged = true
	enrage_timer = enrage_duration

	can_enrage = false
	enrage_cooldown_timer = enrage_cooldown

	if sprite:
		sprite.modulate = enrage_modulate

	if light_attack_effect:
		light_attack_effect.modulate = enrage_modulate
	if dash_effect:
		dash_effect.modulate = enrage_modulate
	if slam_effect:
		slam_effect.modulate = enrage_modulate
	if heal_effect:
		heal_effect.modulate = enrage_modulate

	print("ENRAGE STARTED")

func stop_enrage() -> void:
	is_enraged = false
	enrage_timer = 0.0

	if sprite:
		sprite.modulate = normal_modulate

	if light_attack_effect:
		light_attack_effect.modulate = Color(1, 1, 1, 1)
	if dash_effect:
		dash_effect.modulate = Color(1, 1, 1, 1)
	if slam_effect:
		slam_effect.modulate = Color(1, 1, 1, 1)
	if heal_effect:
		heal_effect.modulate = Color(1, 1, 1, 1)

	print("ENRAGE ENDED")

func get_damage_multiplier() -> float:
	return enrage_damage_multiplier if is_enraged else 1.0

func get_light_attack_damage(base_damage: int) -> int:
	return int(round(base_damage * get_damage_multiplier()))

func get_charged_attack_damage() -> int:
	return int(round(charged_attack_damage * get_damage_multiplier()))

func get_slam_damage() -> int:
	return int(round(slam_damage * get_damage_multiplier()))

func _take_damage(hurtbox: Hurtbox) -> void:
	if is_parrying:
		print("PARRY SUCCESS")
		var attacker := hurtbox.owner
		parry_successful = true
		on_successful_parry(attacker)
		return

	if invulnerable:
		return

	update_hp(-hurtbox.damage)

	if hp > 0:
		playerDamaged.emit(hurtbox)
	else:
		playerDamaged.emit(hurtbox)
		hp = 0
		state_machine.ChangeState($StateMachine/Death)

func update_hp(delta: int) -> void:
	hp = clampi(hp + delta, 0, maxHp)

func make_invulnerable(_duration: float = 1.0) -> void:
	invulnerable = true
	hitbox.monitoring = false

	await get_tree().create_timer(_duration).timeout

	invulnerable = false
	hitbox.monitoring = true

func on_successful_parry(attacker: Node) -> void:
	is_parrying = false
	parry_successful = true
	invulnerable = true
	invuln_timer = 0.30

	if attacker != null and attacker.has_method("on_parried"):
		attacker.on_parried()

func play_effect(effect_name: String, _centered: bool = false) -> void:
	match effect_name:
		"light_attack_effect":
			_play_effect_node(light_attack_effect, false)
		"dash":
			_play_effect_node(dash_effect, false)
		"slam":
			_play_effect_node(slam_effect, true)
		"heal_effect":
			_play_effect_node(heal_effect, true)

func _play_effect_node(effect: AnimatedSprite2D, centered: bool) -> void:
	if effect == null:
		return

	effect.visible = true

	if centered:
		effect.flip_h = false
	else:
		effect.flip_h = cardinal_direction == Vector2.LEFT

	effect.play()

func stop_effect(effect_name: String = "") -> void:
	match effect_name:
		"light_attack_effect":
			_stop_effect_node(light_attack_effect)
		"dash":
			_stop_effect_node(dash_effect)
		"slam":
			_stop_effect_node(slam_effect)
		"heal_effect":
			_stop_effect_node(heal_effect)
		"":
			_stop_effect_node(light_attack_effect)
			_stop_effect_node(dash_effect)
			_stop_effect_node(slam_effect)
			_stop_effect_node(heal_effect)

func _stop_effect_node(effect: AnimatedSprite2D) -> void:
	if effect == null:
		return

	effect.stop()
	effect.visible = false

func _on_any_effect_animation_finished(effect: AnimatedSprite2D) -> void:
	_stop_effect_node(effect)

func _on_effect_animation_finished() -> void:
	stop_effect()

func set_checkpoint(pos: Vector2):
	checkpoint_position = pos
	print("New checkpoint set: ", pos)

# =========================
# PLAYER BEHAVIOR HELPERS
# =========================

func register_behavior_attack() -> void:
	if behavior_logger:
		behavior_logger.register_attack_pressed()

func register_behavior_dash() -> void:
	if behavior_logger:
		behavior_logger.register_dash()

func register_behavior_parry() -> void:
	if behavior_logger:
		behavior_logger.register_parry()

func register_behavior_heal() -> void:
	if behavior_logger:
		behavior_logger.register_heal()

func register_behavior_jump() -> void:
	if behavior_logger:
		behavior_logger.register_jump()

func register_behavior_tracked_enemy(new_enemy: Enemy) -> void:
	if behavior_logger:
		behavior_logger.set_tracked_enemy(new_enemy)

func get_behavior_snapshot() -> Dictionary:
	if behavior_logger:
		return behavior_logger.get_behavior_snapshot()
	return {}
	
func register_behavior_light_attack() -> void:
	if behavior_logger:
		behavior_logger.register_light_attack()

func register_behavior_heavy_attack() -> void:
	if behavior_logger:
		behavior_logger.register_heavy_attack()

func register_behavior_slam_attack() -> void:
	if behavior_logger:
		behavior_logger.register_slam_attack()

func die():
	global_position = checkpoint_position
