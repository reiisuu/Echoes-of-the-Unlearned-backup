class_name BossStateBackstep
extends EnemyState

@onready var chase: EnemyState = $"../Chase"

@export var speed: float = 180.0
@export var duration: float = 0.22

var timer: float = 0.0
var dir: float = 0.0

func Enter() -> void:
	var boss := enemy as Boss
	if boss == null:
		return

	boss.mark_attack_used("backstep")

	if enemy.player != null:
		var dx := enemy.player.global_position.x - enemy.global_position.x
		boss.face_player(dx)
		dir = -sign(dx)
	else:
		dir = -1.0 if enemy.cardinal_direction == Vector2.RIGHT else 1.0

	if dir == 0.0:
		dir = -1.0 if enemy.cardinal_direction == Vector2.RIGHT else 1.0

	timer = 0.0
	enemy.velocity.x = 0.0
	enemy.reset_attack_window()

	if enemy.sprite != null and enemy.sprite.sprite_frames != null and enemy.sprite.sprite_frames.has_animation("backstep"):
		enemy.updateAnimation("backstep")
	else:
		enemy.updateAnimation("walk")

func Exit() -> void:
	enemy.velocity.x = 0.0
	enemy.reset_attack_window()

func process(_delta: float) -> EnemyState:
	timer += _delta

	if timer >= duration:
		return chase

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity.x = dir * speed
	return null
