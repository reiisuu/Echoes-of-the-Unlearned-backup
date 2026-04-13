extends Area2D

@export var enemies: Array[NodePath]

@onready var walls = [
	$WallLeft,
	$WallRight
]

var active = false
var finished = false

var encounter_enemies: Array = []
var remaining_enemies := 0

func _ready() -> void:
	print("READY RUNNING")
	set_walls(false)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	print("ENTERED:", body.name)

	if active or finished:
		return

	if body is Player:
		start_encounter()

func start_encounter() -> void:
	encounter_enemies.clear()

	var bodies = get_overlapping_bodies()
	print("BODIES FOUND:", bodies.size())

	for body in bodies:
		print("BODY:", body.name, body)
		if body is Enemy and is_instance_valid(body):
			print("FOUND ENEMY:", body.name)
			encounter_enemies.append(body)

	remaining_enemies = encounter_enemies.size()
	print("ENEMIES IN AREA:", remaining_enemies)

	if remaining_enemies == 0:
		print("NO ENEMIES — SKIP ENCOUNTER")
		finished = true
		return

	for enemy in encounter_enemies:
		if enemy.has_signal("enemyDestroyed"):
			if not enemy.enemyDestroyed.is_connected(_on_enemy_killed):
				enemy.enemyDestroyed.connect(_on_enemy_killed)

	set_walls(true)
	active = true

func _on_enemy_killed(_enemy) -> void:
	if not active:
		return

	remaining_enemies -= 1
	print("Enemy left:", remaining_enemies)

	if remaining_enemies <= 0:
		print("ALL DEAD")
		end_encounter()

func end_encounter() -> void:
	set_walls(false)
	active = false
	finished = true
	print("BARRIER OFF")

	monitoring = false

func set_walls(state: bool) -> void:
	for wall in walls:
		if wall == null:
			continue

		var col = wall.get_node_or_null("CollisionShape2D")
		if col == null:
			continue

		col.set_deferred("disabled", not state)
		wall.visible = state
