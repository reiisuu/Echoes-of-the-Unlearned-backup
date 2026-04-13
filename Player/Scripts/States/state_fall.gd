class_name State_Fall
extends State

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var jump: State = $"../Jump"
@onready var slam: State = $"../Slam"
@onready var attack: State = $"../Attack"
@onready var dash: State = $"../Dash"
@onready var enrage: State = $"../Enrage"

func Enter() -> void:
	player.updateAnimation("fall")

func Process(_delta: float) -> State:
	if player.is_on_floor():
		if player.jump_buffer_timer > 0.0 and player.can_jump():
			return jump

		if abs(player.direction.x) > 0:
			return walk
		return idle

	return null

func Physics(delta: float) -> State:
	player.apply_air_gravity(delta)
	player.apply_jump_cut()
	player.apply_air_movement(delta)
	player.move_and_slide()
	return null

func HandleInput(event: InputEvent) -> State:
	if event.is_action_pressed("crouch") and not event.is_echo():
		if not player.has_slammed_in_air:
			return slam

	if event.is_action_pressed("light_attack") and not event.is_echo():
		return attack

	if event.is_action_pressed("dash") and not event.is_echo() and player.can_dash:
		return dash

	if event.is_action_pressed("jump") and not event.is_echo() and player.can_air_jump():
		return jump

	if event.is_action_pressed("enrage") and not event.is_echo() and player.can_enrage:
		return enrage

	return null
