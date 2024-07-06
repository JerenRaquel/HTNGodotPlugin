class_name HTNAgentLink
extends Node

signal orders_recieved

@export var group_tag: String = "global"

var _link_ID: String
var _group_tag: String
var _agent: Node
var awaiting_orders := false

func _exit_tree() -> void:
	HTNCommincationHUB.unregister(self)

func initialize(agent: Node) -> void:
	_agent = agent
	orders_recieved.connect(func() -> void: awaiting_orders = false)
	HTNCommincationHUB.register(self, group_tag)

func request_orders() -> void:
	awaiting_orders = true
	HTNCommincationHUB.request_orders(self)

func get_world_states() -> Dictionary:
	return {
		"awaiting_orders": awaiting_orders,
	}
