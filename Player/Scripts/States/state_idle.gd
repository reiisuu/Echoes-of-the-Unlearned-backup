class_name State_Idle
extends State

@onready var walk: State = $"../Walk"
@onready var attack: State = $"../Attack"
@onready var charged_attack: State = $"../ChargedAttack"
@onready var dash: State = $"../Dash"
@onready var parry: State = $"../Parry"
@onready var jump: State = $"../Jump"
@onready var heal: State = $"../Heal"
@onready var enrage: State = $"../Enrage"

func Enter() -> void:
	player.is_parrying = false
	player.velocity.x = 0.0
	player.updateAnimation("idle")

func Process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	return null

func HandleInput(event: InputEvent) -> State:
	if event.is_action_pressed("light_attack") and not event.is_echo():
		return attack

	if event.is_action_pressed("charged_attack") and not event.is_echo():
		print("charged pressed")
		if player.can_use_charged_attack():
			print("charged allowed")
			player.start_charged_attack_cooldown()
			return charged_attack
		else:
			print("charged blocked")

	if event.is_action_pressed("heal") and not event.is_echo():
		print("heal pressed")
		if player.can_start_heal():
			print("heal allowed")
			return heal
		else:
			print("heal blocked")

	if event.is_action_pressed("parry") and not event.is_echo():
		return parry

	if event.is_action_pressed("dash") and not event.is_echo() and player.can_dash:
		return dash

	if event.is_action_pressed("jump") and not event.is_echo():
		return jump

	if event.is_action_pressed("stance") and not event.is_echo():
		player.isRunning = !player.isRunning
		
	if event.is_action_pressed("enrage") and not event.is_echo() and player.can_enrage:
		return enrage

	return null
