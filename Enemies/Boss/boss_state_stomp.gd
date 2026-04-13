class_name BossStateStomp
extends EnemyState

@onready var chase: EnemyState = $"../Chase"

@export var total_duration: float = 1.33
@export var hit_start_frame: int = 9
@export var hit_end_frame: int = 13

var timer: float = 0.0
var active: bool = false

func Enter() -> void:
	var boss := enemy as Boss
	boss.mark_attack_used("stomp")
	boss.use_attack_box("stomp")

	timer = 0.0
	active = false

	enemy.reset_attack_window()
	enemy.updateAnimation("stomp")

func Exit() -> void:
	enemy.reset_attack_window()

func process(_delta: float) -> EnemyState:
	timer += _delta

	var f := enemy.sprite.frame
	var should_hit := f >= hit_start_frame and f <= hit_end_frame

	if should_hit and not active:
		active = true
		enemy.begin_attack_window()
	elif not should_hit and active:
		active = false
		enemy.end_attack_window()

	if timer >= total_duration:
		return chase

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity.x = 0.0
	return null
