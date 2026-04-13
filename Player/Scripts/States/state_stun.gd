class_name State_Stun
extends State

@export var knockback_speed: float = 200.0
@export var deceleration_speed: float = 10.0
@export var invulnerable_duration: float = 1.0

var hurtbox: Hurtbox
var direction: Vector2
var next_state: State = null

@onready var idle: State = $"../Idle"
@onready var fall: State = $"../Fall"

func Init() -> void:
	player.playerDamaged.connect(_player_damaged)

func Enter() -> void:
	if not player.sprite.animation_finished.is_connected(_animation_finished):
		player.sprite.animation_finished.connect(_animation_finished)

	if hurtbox != null:
		direction = player.global_position.direction_to(hurtbox.global_position)
		player.velocity = direction * -knockback_speed
	else:
		player.velocity = Vector2.ZERO

	player.updateAnimation("stun")
	player.make_invulnerable(invulnerable_duration)

	if player.effect_animation != null and player.effect_animation.has_animation("damaged"):
		player.effect_animation.play("damaged")

func Exit() -> void:
	next_state = null

	if player.sprite.animation_finished.is_connected(_animation_finished):
		player.sprite.animation_finished.disconnect(_animation_finished)

func Process(delta: float) -> State:
	player.velocity = player.velocity.move_toward(Vector2.ZERO, deceleration_speed * 100.0 * delta)
	return next_state

func Physics(delta: float) -> State:
	if not player.is_on_floor():
		player.apply_air_gravity(delta)

	player.move_and_slide()
	return null

func HandleInput(_event: InputEvent) -> State:
	return null

func _player_damaged(_hurtbox: Hurtbox) -> void:
	hurtbox = _hurtbox
	state_machine.ChangeState(self)

func _animation_finished() -> void:
	if player.is_on_floor():
		next_state = idle
	else:
		next_state = fall
