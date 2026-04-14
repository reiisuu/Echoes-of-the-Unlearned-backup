class_name BossDecisionBrain
extends Node

@export var think_interval: float = 0.18
@export var debug_prints: bool = true

var boss: Boss = null
var ai_context: BossAIContext = null
var api_client: BossAPIClient = null

var think_timer: float = 0.0
var waiting_for_response: bool = false

var queued_action: String = ""
var last_reason: String = ""
var last_state_name: String = ""

func _ready() -> void:
	boss = get_parent() as Boss
	if boss == null:
		return

	ai_context = boss.get_node_or_null("BossAIContext") as BossAIContext
	api_client = boss.get_node_or_null("BossAPIClient") as BossAPIClient

	if api_client != null:
		api_client.decision_received.connect(_on_decision_received)
		api_client.request_failed.connect(_on_request_failed)

func _physics_process(delta: float) -> void:
	if boss == null or ai_context == null or api_client == null:
		return

	if waiting_for_response:
		return

	if boss.state_machine == null or boss.state_machine.current_state == null:
		return

	last_state_name = String(boss.state_machine.current_state.name)

	think_timer += delta
	if think_timer < think_interval:
		return

	think_timer = 0.0
	waiting_for_response = true

	var payload := ai_context.get_payload()

	if debug_prints:
		print("BossDecisionBrain sending payload: ", payload)

	api_client.request_decision(payload)

func _on_decision_received(action: String, reason: String, _raw_response: Dictionary) -> void:
	waiting_for_response = false

	# keep latest suggestion only
	queued_action = action
	last_reason = reason

	if debug_prints:
		print("BossDecisionBrain queued action: ", action, " | reason: ", reason, " | state: ", last_state_name)

func _on_request_failed(error_message: String) -> void:
	waiting_for_response = false

	if debug_prints:
		print("BossDecisionBrain request failed: ", error_message)

func consume_decision() -> String:
	var out := queued_action
	queued_action = ""
	return out

func peek_decision() -> String:
	return queued_action

func clear_decision() -> void:
	queued_action = ""
	last_reason = ""
