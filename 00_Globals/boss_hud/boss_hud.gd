class_name BossHud
extends CanvasLayer

@onready var hp_bar: ProgressBar = $ProgressBar
@onready var lives_label: Label = $Label

func _ready() -> void:
	add_to_group("boss_hud")  # 🔥 FIX HERE

	if hp_bar:
		hp_bar.min_value = 0
		hp_bar.max_value = 100
		hp_bar.value = 100
		if hp_bar.has_method("set_bar_value"):
			hp_bar.set_bar_value(100)

	if lives_label:
		lives_label.text = "Lives: 3"

func update_health_bar(hp: float, max_hp: float) -> void:
	if hp_bar == null:
		hp_bar = get_node_or_null("ProgressBar")

	if hp_bar == null:
		return

	var value: float = 0.0
	if max_hp > 0.0:
		value = (hp / max_hp) * 100.0

	if hp_bar.has_method("set_bar_value"):
		hp_bar.set_bar_value(value)
	else:
		hp_bar.value = value

func update_lives(current_lives: int) -> void:
	if lives_label == null:
		lives_label = get_node_or_null("Label")

	if lives_label == null:
		return

	lives_label.text = "Lives: " + str(current_lives)
