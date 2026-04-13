class_name EnemyStateDestroy
extends EnemyState

@export var anim_name: String = "destroy"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0


@export_category("AI")

var _damage_position: Vector2
var _direction: Vector2 


func Init() -> void:
	enemy.enemyDestroyed.connect( _on_enemy_destroyed )
	pass

func Enter() -> void:
	
	_direction = enemy.global_position.direction_to( _damage_position )
	enemy.setDirection(_direction)
	enemy.velocity = _direction * -knockback_speed
	enemy.updateAnimation(anim_name)
	enemy.sprite.animation_finished.connect( _on_animation_finished )

func Exit() -> void:
	pass

func process(_delta: float) -> EnemyState:
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null

func physics(_delta: float) -> EnemyState:
	return null

func _on_enemy_destroyed ( hurtbox : Hurtbox ) -> void:
	_damage_position = hurtbox.global_position
	state_machine.ChangeState( self )


func _on_animation_finished( ) -> void:
	enemy.queue_free()
