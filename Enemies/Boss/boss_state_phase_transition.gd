class_name BossStatePhaseTransition
extends EnemyState

@onready var chase: EnemyState = $"../Chase"

@export var anim_name: String = "stun"
@export var duration: float = 0.5

var timer: float = 0.0

func Enter() -> void:
	timer = 0.0

	enemy.velocity.x = 0.0
	enemy.reset_attack_window()

	if enemy.player != null:
		var boss := enemy as Boss
		if boss != null:
			var dx := enemy.player.global_position.x - enemy.global_position.x
			boss.face_player(dx)

	if enemy.sprite != null and enemy.sprite.sprite_frames != null and enemy.sprite.sprite_frames.has_animation(anim_name):
		enemy.updateAnimation(anim_name)
	else:
		enemy.updateAnimation("idle")

func Exit() -> void:
	enemy.velocity.x = 0.0
	enemy.reset_attack_window()

func process(_delta: float) -> EnemyState:
	timer += _delta

	if timer >= duration:
		return chase

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity.x = 0.0
	return null
