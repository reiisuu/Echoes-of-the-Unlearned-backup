class_name State_Run
extends State

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var jump: State = $"../Jump"
@onready var fall: State = $"../Fall"
@onready var attack: State = $"../Attack"
@onready var dash: State = $"../Dash"
@onready var parry: State = $"../Parry"
@onready var charged_attack: State = $"../ChargedAttack"
@onready var heal: State = $"../Heal"
@onready var enrage: State = $"../Enrage"

func Enter() -> void:
	player.updateAnimation("run")

func Process(_delta: float) -> State:
	if not player.is_on_floor():
		if player.velocity.y < 0.0:
			return jump
		return fall

	if player.jump_buffer_timer > 0.0 and player.can_jump():
		return jump

	if player.direction == Vector2.ZERO:
		return idle

	if not player.isRunning:
		return walk

	player.setDirection()
	player.updateAnimation("run")
	return null

func Physics(delta: float) -> State:
	player.apply_ground_movement(delta, player.run_speed_multiplier)
	player.move_and_slide()
	return null

func HandleInput(event: InputEvent) -> State:
	if event.is_action_pressed("light_attack") and not event.is_echo():
		return attack

	if event.is_action_pressed("charged_attack") and not event.is_echo():
		if player.can_use_charged_attack():
			player.start_charged_attack_cooldown()
			return charged_attack

	if event.is_action_pressed("heal") and not event.is_echo():
		if player.can_start_heal():
			return heal

	if event.is_action_pressed("dash") and not event.is_echo() and player.can_dash:
		return dash

	if event.is_action_pressed("jump") and not event.is_echo():
		return jump

	if event.is_action_pressed("parry") and not event.is_echo():
		return parry

	if event.is_action_pressed("stance") and not event.is_echo():
		player.isRunning = false
		return walk
		
	if event.is_action_pressed("enrage") and not event.is_echo() and player.can_enrage:
		return enrage

	return null
