class_name Boss
extends Enemy

@export var normal_cooldown: float = 0.75
@export var heavy_cooldown: float = 1.8
@export var stomp_cooldown: float = 2.2
@export var punish_cooldown: float = 1.1
@export var backstep_cooldown: float = 1.4

@export var phase_2_hp_ratio: float = 0.5
@export var base_chase_speed: float = 42.0
@export var phase_2_chase_speed: float = 58.0

@export var punish_distance: float = 42.0
@export var backstep_trigger_distance: float = 22.0

var in_phase_2: bool = false
var max_hp_value: int = 1

var _cooldowns := {
	"normal": 0.0,
	"heavy": 0.0,
	"stomp": 0.0,
	"punish": 0.0,
	"backstep": 0.0
}

@onready var body_hurtbox: Hurtbox = $Hurtbox
@onready var attack_hurtbox: Hurtbox = $AttackHurtbox
@onready var heavy_hurtbox: Hurtbox = $HeavyHurtbox
@onready var stomp_hurtbox: Hurtbox = $StompHurtbox

var _attack_box_base_position: Vector2 = Vector2.ZERO
var _heavy_box_base_position: Vector2 = Vector2.ZERO
var _stomp_box_base_position: Vector2 = Vector2.ZERO

var _active_attack_box: Hurtbox = null

func _ready() -> void:
	super()

	max_hp_value = hp

	if attack_hurtbox:
		_attack_box_base_position = attack_hurtbox.position
	if heavy_hurtbox:
		_heavy_box_base_position = heavy_hurtbox.position
	if stomp_hurtbox:
		_stomp_box_base_position = stomp_hurtbox.position

	_connect_attack_hurtbox_signals()

	if attack_hurtbox:
		attack_hurtbox.monitoring = false
	if heavy_hurtbox:
		heavy_hurtbox.monitoring = false
	if stomp_hurtbox:
		stomp_hurtbox.monitoring = false

	_active_attack_box = null
	reset_attack_window()

func _physics_process(_delta: float) -> void:
	_tick_cooldowns(_delta)
	_try_enter_phase_2()
	super(_delta)

func _tick_cooldowns(_delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = max(_cooldowns[key] - _delta, 0.0)

func _try_enter_phase_2() -> void:
	if in_phase_2:
		return

	var threshold := int(ceil(float(max_hp_value) * phase_2_hp_ratio))
	threshold = max(threshold, 1)

	if hp <= threshold:
		in_phase_2 = true

func get_chase_speed() -> float:
	return phase_2_chase_speed if in_phase_2 else base_chase_speed

func can_use_attack(name: String) -> bool:
	if not _cooldowns.has(name):
		return true
	return _cooldowns[name] <= 0.0

func mark_attack_used(name: String) -> void:
	match name:
		"normal":
			_cooldowns["normal"] = normal_cooldown
		"heavy":
			_cooldowns["heavy"] = heavy_cooldown
		"stomp":
			_cooldowns["stomp"] = stomp_cooldown
		"punish":
			_cooldowns["punish"] = punish_cooldown
		"backstep":
			_cooldowns["backstep"] = backstep_cooldown

func face_player(dx: float) -> void:
	if abs(dx) < 0.01:
		return
	setDirection(Vector2(sign(dx), 0.0))

func _apply_box_facing() -> void:
	super()

	var facing_sign := 1.0 if cardinal_direction == Vector2.RIGHT else -1.0

	if attack_hurtbox:
		attack_hurtbox.position.x = abs(_attack_box_base_position.x) * facing_sign
		attack_hurtbox.position.y = _attack_box_base_position.y

	if heavy_hurtbox:
		heavy_hurtbox.position.x = abs(_heavy_box_base_position.x) * facing_sign
		heavy_hurtbox.position.y = _heavy_box_base_position.y

	if stomp_hurtbox:
		stomp_hurtbox.position = _stomp_box_base_position

func _connect_attack_hurtbox_signals() -> void:
	_connect_single_attack_hurtbox(attack_hurtbox)
	_connect_single_attack_hurtbox(heavy_hurtbox)
	_connect_single_attack_hurtbox(stomp_hurtbox)

func _connect_single_attack_hurtbox(box: Hurtbox) -> void:
	if box == null:
		return

	# Make sure the attack hurtboxes behave like the enemy attack hurtbox:
	# they damage the player only while monitoring is enabled.
	if box.area_entered.is_connected(_on_attack_hurtbox_area_entered):
		box.area_entered.disconnect(_on_attack_hurtbox_area_entered)

	box.area_entered.connect(_on_attack_hurtbox_area_entered)

func _on_attack_hurtbox_area_entered(area: Area2D) -> void:
	if not attack_can_damage:
		return

	if attack_has_hit:
		return

	if area == null:
		return

	# Same flow as your enemy attack logic:
	# if the player's hitbox/hurtbox system calls takeDamage through Hurtbox/Hitbox interaction,
	# enabling the boss attack hurtbox is enough.
	# This guard prevents multi-hit spam from one swing.
	attack_has_hit = true

func use_attack_box(box_name: String) -> void:
	reset_attack_window()

	match box_name:
		"attack":
			_active_attack_box = attack_hurtbox
		"heavy":
			_active_attack_box = heavy_hurtbox
		"stomp":
			_active_attack_box = stomp_hurtbox
		_:
			_active_attack_box = null

func begin_attack_window() -> void:
	attack_can_damage = true
	attack_has_hit = false

	if _active_attack_box:
		_active_attack_box.monitoring = true

func end_attack_window() -> void:
	attack_can_damage = false

	if _active_attack_box:
		_active_attack_box.monitoring = false

func reset_attack_window() -> void:
	attack_can_damage = false
	attack_has_hit = false

	if attack_hurtbox:
		attack_hurtbox.monitoring = false
	if heavy_hurtbox:
		heavy_hurtbox.monitoring = false
	if stomp_hurtbox:
		stomp_hurtbox.monitoring = false

	_active_attack_box = null

func should_force_punish(distance_to_player: float) -> bool:
	if not can_use_attack("punish"):
		return false
	if distance_to_player > punish_distance:
		return false
	return _player_is_committed()

func should_backstep(distance_to_player: float) -> bool:
	if not can_use_attack("backstep"):
		return false
	if distance_to_player > backstep_trigger_distance:
		return false
	return _player_is_committed()

func _player_is_committed() -> bool:
	if player == null:
		return false

	var attacking: bool = bool(player.get("is_attacking"))
	var healing: bool = bool(player.get("is_healing"))
	var parrying: bool = bool(player.get("is_parrying"))
	var charging: bool = bool(player.get("is_charging_attack"))

	return attacking or healing or parrying or charging
