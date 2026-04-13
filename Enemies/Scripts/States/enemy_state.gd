class_name EnemyState
extends Node

var enemy: Enemy
var state_machine: EnemyStateMachine

func Init() -> void:
	pass

func Enter() -> void:
	pass

func Exit() -> void:
	pass

func process(_delta: float) -> EnemyState:
	return null

func physics(_delta: float) -> EnemyState:
	return null
