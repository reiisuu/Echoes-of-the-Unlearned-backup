class_name Hurtbox
extends Area2D

@export var damage: int = 1

func _ready() -> void:
	area_entered.connect(areaEntered)
	print("Hurtbox activated")

func areaEntered(a: Area2D) -> void:
	if not (a is Hitbox):
		return

	var owner_enemy = get_parent()
	if owner_enemy == null:
		return

	if owner_enemy.get("attack_can_damage") == false:
		return

	if owner_enemy.get("attack_has_hit") == true:
		return

	a.takeDamage(self)

	if owner_enemy.has_method("mark_attack_hit"):
		owner_enemy.mark_attack_hit()
