class_name PlayerStateMachine
extends Node

var states: Array[State] = []
var prev_state: State
var current_state: State


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if current_state == null:
		return
	

	var new_state = current_state.Process(delta)
	if new_state != null:
		ChangeState(new_state)


func _physics_process(delta: float) -> void:
	if current_state:
		ChangeState(current_state.Physics(delta))


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		ChangeState(current_state.HandleInput(event))


func Initialize(_player: Player) -> void:
	states.clear()

	for c in get_children():
		if c is State:
			c.player = _player
			states.append(c)
			
	if states.size() == 0:
		return
		
	states[0].player = _player
	states[0].state_machine = self
	
	for state in states:
		state.Init()
	
	ChangeState(states[0])
	process_mode = Node.PROCESS_MODE_INHERIT


func ChangeState(new_state: State) -> void:
	if new_state == null or new_state == current_state:
		return

	if current_state:
		current_state.Exit()

	prev_state = current_state
	current_state = new_state
	print("Changed to: ", current_state.name)
	current_state.Enter()
