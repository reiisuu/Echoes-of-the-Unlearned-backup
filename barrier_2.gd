extends Area2D

@export var enemies: Array[NodePath]

@onready var walls = []

var active = false
var finished = false
var can_trigger = false

var encounter_enemies: Array = []
var remaining_enemies := 0


func _ready() -> void:
	print("READY RUNNING")
	
	walls = find_children("Wall*", "", true)
	print("WALLS FOUND:", walls)

	set_walls(false)

	# connect signal
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# wait for physics to settle
	await get_tree().physics_frame

	# ✅ now safe to detect player
	can_trigger = true

	print("READY DONE")


func _on_body_entered(body) -> void:
	print("ENTERED:", body.name)

	if not can_trigger:
		print("IGNORED (startup)")
		return

	if active or finished:
		return

	if not body.is_in_group("player"):
		return

	print("PLAYER DETECTED")
	start_encounter()


func start_encounter() -> void:
	print("🔥 START ENCOUNTER CALLED")

	encounter_enemies.clear()

	var bodies = get_overlapping_bodies()
	print("BODIES FOUND:", bodies.size())

	for body in bodies:
		print("BODY:", body.name)

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

	# ✅ TURN WALLS ON
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
	print("\n=== SET WALLS ===", state)
	print("WALL COUNT:", walls.size())

	for wall in walls:
		if wall == null:
			print("❌ NULL WALL")
			continue

		print("➡ WALL:", wall.name)

		var col = wall.find_child("CollisionShape2D", true, false)

		if col == null:
			print("❌ NO COLLISION IN:", wall.name)
			continue

		print("   BEFORE:", col.disabled)

		col.disabled = not state

		print("   AFTER:", col.disabled)

		# 🔥 FORCE update (important for physics refresh)
		col.call_deferred("set_disabled", not state)
