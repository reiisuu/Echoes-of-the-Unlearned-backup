class_name State_Heal
extends State

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var fall: State = $"../Fall"
@onready var run: State = $"../Run"

@export var heal_duration: float = 0.5  # adjust to match animation

var heal_applied: bool = false
var timer: float = 0.0

func Enter() -> void:
	player.register_behavior_heal()
	player.is_healing = true
	player.velocity = Vector2.ZERO
	heal_applied = false
	timer = 0.0

	# 🔥 FORCE animation (bypass updateAnimation issues)
	if player.sprite:
		player.sprite.stop()
		player.sprite.play("heal")

func Exit() -> void:
	player.is_healing = false
	player.stop_effect()

func Process(delta: float) -> State:
	timer += delta

	# Apply heal mid-animation
	if not heal_applied and timer >= heal_duration * 0.4:
		heal_applied = true
		player.apply_heal()
		player.play_effect("heal_effect", true)

	# End heal state
	if timer >= heal_duration:
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
