class_name BossAPIClient
extends Node

signal decision_received(action: String, reason: String, raw_response: Dictionary)
signal request_failed(error_message: String)

@export var api_url: String = "http://127.0.0.1:8000/decide_action"
@export var debug_prints: bool = true

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func request_decision(payload: Dictionary) -> void:
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify(payload)

	var err := _http.request(api_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		var msg := "BossAPIClient request error: %s" % err
		if debug_prints:
			print(msg)
		request_failed.emit(msg)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var text := body.get_string_from_utf8()

	if debug_prints:
		print("BossAPIClient HTTP ", response_code, " | ", text)

	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("Request failed with result: %s" % result)
		return

	if response_code < 200 or response_code >= 300:
		request_failed.emit("Bad response code: %s" % response_code)
		return

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("Invalid JSON from API")
		return

	var action := String(parsed.get("action", ""))
	var reason := String(parsed.get("reason", ""))
	decision_received.emit(action, reason, parsed)
