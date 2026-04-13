class_name EnemyStateMachine
extends Node

var states: Array[EnemyState] = []
var prev_state: EnemyState
var current_state: EnemyState

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if current_state == null:
		return
	ChangeState(current_state.process(delta))

func _physics_process(delta: float) -> void:
	if current_state == null:
		return
	ChangeState(current_state.physics(delta))

func Initialize(_enemy: Enemy) -> void:
	states.clear()

	for c in get_children():
		if c is EnemyState:
			var state := c as EnemyState
			state.enemy = _enemy
			state.state_machine = self
			states.append(state)

	for s in states:
		s.Init()

	if states.size() > 0:
		ChangeState(states[0])
		process_mode = Node.PROCESS_MODE_INHERIT

func ChangeState(new_state: EnemyState) -> void:


	if new_state == null or new_state == current_state:
		return

	if current_state != null:
		current_state.Exit()

	prev_state = current_state
	current_state = new_state
	# print("CHANGED TO: ", current_state.name)
	current_state.Enter()
