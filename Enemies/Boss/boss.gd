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

@onready var boss_ai_context: BossAIContext = $BossAIContext
@onready var boss_api_client: BossAPIClient = $BossAPIClient
@onready var boss_decision_brain: BossDecisionBrain = $BossDecisionBrain

var _attack_box_base_position: Vector2 = Vector2.ZERO
var _heavy_box_base_position: Vector2 = Vector2.ZERO
var _stomp_box_base_position: Vector2 = Vector2.ZERO

var _active_attack_box: Hurtbox = null

func _ready() -> void:
	super()

	if max_hp < hp:
		max_hp = hp

	max_hp_value = hp

	if attack_hurtbox:
		_attack_box_base_position = attack_hurtbox.position
	if heavy_hurtbox:
		_heavy_box_base_position = heavy_hurtbox.position
	if stomp_hurtbox:
		_stomp_box_base_position = stomp_hurtbox.position

	if attack_hurtbox:
		attack_hurtbox.monitoring = false
	if heavy_hurtbox:
		heavy_hurtbox.monitoring = false
	if stomp_hurtbox:
		stomp_hurtbox.monitoring = false

	_active_attack_box = null
	reset_attack_window()

func _physics_process(delta: float) -> void:
	_tick_cooldowns(delta)
	_try_enter_phase_2()
	super(delta)

func _tick_cooldowns(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = max(_cooldowns[key] - delta, 0.0)

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

func can_use_light_attack() -> bool:
	return can_use_attack("normal")

func can_use_heavy_attack() -> bool:
	return can_use_attack("heavy")

func can_use_stomp() -> bool:
	return can_use_attack("stomp")

func can_use_backstep() -> bool:
	return can_use_attack("backstep")

func can_use_punish() -> bool:
	return can_use_attack("punish")

func can_use_phase_transition() -> bool:
	return in_phase_2 and not has_meta("phase_transition_done")

func mark_attack_used(name: String) -> void:
	last_attack_used = name

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

	if boss_ai_context != null:
		boss_ai_context.add_action(name)

func mark_attack_hit() -> void:
	attack_has_hit = true

	if _active_attack_box:
		_active_attack_box.monitoring = false

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

func use_attack_box(box_name: String) -> void:
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

	var attacking: bool = false
	var healing: bool = false
	var parrying: bool = false
	var charging: bool = false

	if player.get("is_attacking") != null:
		attacking = player.get("is_attacking")
	if player.get("is_healing") != null:
		healing = player.get("is_healing")
	if player.get("is_parrying") != null:
		parrying = player.get("is_parrying")
	if player.get("is_charging_attack") != null:
		charging = player.get("is_charging_attack")

	return attacking or healing or parrying or charging

func get_ai_action() -> String:
	if boss_decision_brain != null:
		return boss_decision_brain.consume_decision()
	return ""

func get_ai_reason() -> String:
	if boss_decision_brain != null:
		return boss_decision_brain.last_reason
	return ""
