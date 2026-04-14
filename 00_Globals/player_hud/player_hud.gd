class_name BossHud
extends CanvasLayer

@onready var hp_bar: TextureProgressBar = $Control/HPMarginContainer/NinePatchRect/HPBar

func _ready() -> void:
	add_to_group("player_hud")

	if hp_bar:
		hp_bar.min_value = 0
		hp_bar.max_value = 100
		hp_bar.value = 100

func update_health_bar(hp: float, max_hp: float) -> void:
	if hp_bar == null:
		hp_bar = get_node_or_null("Control/HPMarginContainer/NinePatchRect/HPBar")

	if hp_bar == null:
		return

	var value: float = 0.0
	if max_hp > 0.0:
		value = (hp / max_hp) * 100.0

	hp_bar.value = value
