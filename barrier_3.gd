extends Area2D

@export var boss_path: NodePath

@onready var walls = []

var active = false
var finished = false
var can_trigger = false

var boss = null


func _ready() -> void:
	print("READY RUNNING")
	
	walls = find_children("Wall*", "", true)
	print("WALLS FOUND:", walls)

	set_walls(false)

	boss = get_node_or_null(boss_path)
	if boss == null:
		print("❌ NO BOSS ASSIGNED")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	await get_tree().physics_frame
	can_trigger = true

	print("READY DONE")


func _process(_delta: float) -> void:
	if not active:
		return

	var player = PlayerManager.player
	if player == null:
		return

	if player.state_machine != null and player.state_machine.current_state is State_Death:
		print("PLAYER DIED -> RESET BOSS BARRIER")
		_reset_on_player_death()


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

	if boss == null:
		print("❌ NO BOSS — SKIP")
		finished = true
		return

	if boss.has_signal("enemyDestroyed"):
		if not boss.enemyDestroyed.is_connected(_on_boss_killed):
			boss.enemyDestroyed.connect(_on_boss_killed)
			print("✅ CONNECTED TO BOSS")
	else:
		print("❌ BOSS HAS NO SIGNAL")

	set_walls(true)
	active = true


func _on_boss_killed(_boss) -> void:
	print("👑 BOSS KILLED")

	if not active:
		return

	end_encounter()


func end_encounter() -> void:
	set_walls(false)
	active = false
	finished = true
	print("BARRIER OFF")

	monitoring = false


func _reset_on_player_death() -> void:
	if not active:
		return

	set_walls(false)
	active = false
	finished = false
	can_trigger = false

	call_deferred("_reenable_trigger_after_death")


func _reenable_trigger_after_death() -> void:
	await get_tree().physics_frame
	can_trigger = true


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

		col.call_deferred("set_disabled", not state)
