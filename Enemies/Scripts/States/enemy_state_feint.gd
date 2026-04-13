class_name EnemyStateFeint
extends EnemyState

@export var anim_name: String = "attack"
@export var feint_duration: float = 0.45
@export var convert_to_heavy_if_parry: bool = true
@export var convert_to_attack_if_dash: bool = true

@export var return_state: EnemyState
@export var punish_attack_state: EnemyState
@export var heavy_attack_state: EnemyState

var _timer: float = 0.0
var _committed_followup: bool = false

func Enter() -> void:
	_timer = 0.0
	_committed_followup = false
	enemy.velocity = Vector2.ZERO

	if enemy.player != null:
		var dx := enemy.player.global_position.x - enemy.global_position.x
		if dx != 0:
			enemy.setDirection(Vector2(sign(dx), 0))

	if enemy.hitbox:
		enemy.hitbox.monitoring = false
		var shape: CollisionShape2D = enemy.hitbox.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = true

	if enemy.sprite:
		enemy.sprite.stop()
		enemy.sprite.frame = 0
		enemy.sprite.play(anim_name)

	print(enemy.name, " ENTER FEINT | anim = ", anim_name)

func Exit() -> void:
	enemy.velocity = Vector2.ZERO
	print(enemy.name, " EXIT FEINT")

func process(delta: float) -> EnemyState:
	_timer += delta
	enemy.velocity = Vector2.ZERO

	if enemy.player == null:
		return return_state

	if not _committed_followup and _timer >= feint_duration * 0.45:
		var player_state = enemy.player.state_machine.current_state
		var state_name := ""
		if player_state != null:
			state_name = String(player_state.name).to_lower()

		# Punish early parry
		if convert_to_heavy_if_parry and state_name.contains("parry") and heavy_attack_state != null and enemy.can_use_heavy_attack():
			enemy.mark_attack_used("heavy")
			_committed_followup = true
			return heavy_attack_state

		# Punish panic dash
		if convert_to_attack_if_dash and state_name.contains("dash") and punish_attack_state != null and enemy.can_use_normal_attack():
			enemy.mark_attack_used("normal")
			_committed_followup = true
			return punish_attack_state

	# If player is known to parry often, sometimes convert anyway
	if not _committed_followup and _timer >= feint_duration * 0.75:
		if enemy.expects_parry() and heavy_attack_state != null and enemy.can_use_heavy_attack():
			enemy.mark_attack_used("heavy")
			_committed_followup = true
			return heavy_attack_state

	if _timer >= feint_duration:
		return return_state

	return null

func physics(_delta: float) -> EnemyState:
	enemy.velocity = Vector2.ZERO
	return null
