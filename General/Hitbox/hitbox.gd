class_name Hitbox
extends Area2D

signal damaged(hurtbox: Hurtbox)

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func takeDamage(hurtbox: Hurtbox) -> void:
	print("takeDamage : ", hurtbox.damage)
	damaged.emit(hurtbox)
