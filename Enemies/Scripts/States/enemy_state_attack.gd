class_name EnemyStateAttack
extends EnemyState

@export var anim_name: String = "attack"
@export var hit_frame: int = 5
@export var return_state: EnemyState

var _finished: bool = false
var _last_frame: int = -1

func Enter() -> void:
	enemy.mark_attack_used("normal")

	_finished = false
	_last_frame = -1

	enemy.velocity = Vector2.ZERO
	enemy.direction = Vector2.ZERO
	enemy.reset_attack_window()

	if enemy.player != null:
		var dx := enemy.player.global_position.x - enemy.global_position.x
		if dx != 0.0:
			enemy.setDirection(Vector2(sign(dx), 0.0))

	if enemy.sprite:
		enemy.sprite.stop()
		enemy.sprite.frame = 0
		enemy.sprite.play(anim_name)

	print("ENTER ATTACK")

func Exit() -> void:
	enemy.end_attack_window()
	enemy.velocity = Vector2.ZERO

func process(_delta: float) -> EnemyState:
	if enemy.sprite == null:
		return return_state

	if enemy.sprite.animation != anim_name:
		return null

	var current_frame := enemy.sprite.frame
	var frame_count := enemy.sprite.sprite_frames.get_frame_count(anim_name)

	if current_frame == hit_frame and _last_frame != hit_frame:
		enemy.begin_attack_window()
		print("HURTBOX ON")

	if _last_frame == hit_frame and current_frame != hit_frame:
		enemy.end_attack_window()
		print("HURTBOX OFF")

	if frame_count > 0 and current_frame >= frame_count - 1:
		_finished = true

	_last_frame = current_frame

	if _finished:
		enemy.end_attack_window()
		return return_state

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity.x = 0.0
	return null
