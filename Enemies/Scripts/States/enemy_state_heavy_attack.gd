class_name EnemyStateHeavyAttack
extends EnemyState

@export var anim_name: String = "heavy"
@export var attack_duration: float = 1.0
@export var hit_start_time: float = 0.34
@export var hit_end_time: float = 0.52
@export var return_state: EnemyState
@export var punish_followup_state: EnemyState

var _timer: float = 0.0
var _hitbox_active: bool = false

func Enter() -> void:
	enemy.mark_attack_used("heavy")

	_timer = 0.0
	_hitbox_active = false
	enemy.velocity = Vector2.ZERO

	if enemy.player != null:
		var dx := enemy.player.global_position.x - enemy.global_position.x
		if dx != 0:
			enemy.setDirection(Vector2(sign(dx), 0))

	_set_hitbox_enabled(false)

	if enemy.sprite:
		enemy.sprite.stop()
		enemy.sprite.frame = 0
		enemy.sprite.play(anim_name)

	print(enemy.name, " ENTER HEAVY ATTACK | anim = ", anim_name)

func Exit() -> void:
	_set_hitbox_enabled(false)
	enemy.velocity = Vector2.ZERO
	print(enemy.name, " EXIT HEAVY ATTACK")

func process(delta: float) -> EnemyState:
	_timer += delta
	enemy.velocity = Vector2.ZERO

	if _timer >= hit_start_time and _timer <= hit_end_time:
		if not _hitbox_active:
			_hitbox_active = true
			_set_hitbox_enabled(true)
			print(enemy.name, " HEAVY HITBOX ON")
	else:
		if _hitbox_active:
			_hitbox_active = false
			_set_hitbox_enabled(false)
			print(enemy.name, " HEAVY HITBOX OFF")

	if _timer >= attack_duration:
		if punish_followup_state != null and enemy.should_do_punish_followup():
			return punish_followup_state
		return return_state

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity = Vector2.ZERO
	return null

func _set_hitbox_enabled(enabled: bool) -> void:
	if enemy.hitbox:
		enemy.hitbox.monitoring = enabled
		var shape: CollisionShape2D = enemy.hitbox.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled
