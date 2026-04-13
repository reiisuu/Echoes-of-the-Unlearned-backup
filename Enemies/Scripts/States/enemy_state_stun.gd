class_name EnemyStateStun
extends EnemyState

@export var anim_name: String = "stun"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0


@export_category("AI")
@export var next_state: EnemyState

var _damage_position : Vector2
var _direction: Vector2 
var _animation_finished : bool = false



func Init() -> void:
	enemy.enemyDamaged.connect( _on_enemy_damaged )
	pass

func Enter() -> void:
	
	
	_animation_finished = false
	_direction = enemy.global_position.direction_to( _damage_position )
	
	
	
	enemy.setDirection(_direction)
	enemy.velocity = _direction * -knockback_speed
	enemy.updateAnimation(anim_name)
	enemy.sprite.animation_finished.connect( _on_animation_finished )

func Exit() -> void:
	enemy.invulnerable = false
	enemy.sprite.animation_finished.disconnect(_on_animation_finished)
	pass

func process(_delta: float) -> EnemyState:
	if _animation_finished == true:
		return next_state
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null

func physics(_delta: float) -> EnemyState:
	return null

func _on_enemy_damaged ( hurtbox : Hurtbox ) -> void:
	_damage_position = hurtbox.global_position
	state_machine.ChangeState( self )


func _on_animation_finished( ) -> void:
	_animation_finished = true
