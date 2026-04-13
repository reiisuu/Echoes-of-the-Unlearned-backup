class_name State_Dash
extends State

@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.35

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var run: State = $"../Run"
@onready var jump: State = $"../Jump"
@onready var fall: State = $"../Fall"
@onready var parry: State = $"../Parry"
@onready var sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"

var dash_timer: float = 0.0
var dash_direction: float = 1.0
var finished_dash: bool = false

func Enter() -> void:
	player.register_behavior_dash()
	finished_dash = false
	player.invulnerable = true
	print("dashing: player is invulnerable")

	dash_timer = dash_duration

	player.can_dash = false
	player.dash_cooldown_timer = dash_cooldown

	if player.direction.x != 0.0:
		dash_direction = sign(player.direction.x)
	else:
		dash_direction = player.get_facing_direction()

	if dash_direction < 0.0:
		player.cardinal_direction = Vector2.LEFT
	else:
		player.cardinal_direction = Vector2.RIGHT

	player.directionChanged.emit(player.cardinal_direction)
	player.sprite.flip_h = player.cardinal_direction == Vector2.LEFT
	player.update_attack_hitbox_direction()

	player.velocity.x = dash_direction * dash_speed
	player.velocity.y = 0.0

	if player.sprite.sprite_frames.has_animation("dash"):
		player.updateAnimation("dash")

	player.play_effect("dash")

func Exit() -> void:
	player.invulnerable = false
	finished_dash = false
	player.stop_effect()
	print("not dashing: player is not invulnerable")

func Process(_delta: float) -> State:
	if finished_dash:
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
	dash_timer -= delta

	player.velocity.x = dash_direction * dash_speed
	player.velocity.y = 0.0
	player.move_and_slide()

	if dash_timer <= 0.0:
		finished_dash = true

	return null

func HandleInput(event: InputEvent) -> State:
	if event.is_action_pressed("parry") and not event.is_echo():
		return parry
	return null
