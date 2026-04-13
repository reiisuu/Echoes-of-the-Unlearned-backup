class_name EnemyStatePunish
extends EnemyState

@export var anim_name: String = "attack"
@export var attack_duration: float = 0.38
@export var hit_start_time: float = 0.08
@export var hit_end_time: float = 0.18
@export var return_state: EnemyState

var _timer: float = 0.0
var _hitbox_active: bool = false

func Enter() -> void:
	enemy.mark_attack_used("punish")

	_timer = 0.0
	_hitbox_active = false
	enemy.velocity = Vector2.ZERO

	if enemy.player != null:
		var dx := enemy.player.global_position.x - enemy.global_position.x
		if dx != 0:
			enemy.setDirection(Vector2(sign(dx), 0))

	enemy.use_normal_hitbox()
	enemy.hitbox.monitoring = false

	if enemy.sprite:
		enemy.sprite.stop()
		enemy.sprite.frame = 0
		enemy.sprite.play(anim_name)

func Exit() -> void:
	enemy.hitbox.monitoring = false
	enemy.velocity = Vector2.ZERO

func process(delta: float) -> EnemyState:
	_timer += delta

	if _timer >= hit_start_time and _timer <= hit_end_time:
		if not _hitbox_active:
			_hitbox_active = true
			enemy.hitbox.monitoring = true
	else:
		if _hitbox_active:
			_hitbox_active = false
			enemy.hitbox.monitoring = false

	if _timer >= attack_duration:
		return return_state

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity = Vector2.ZERO
	return null
