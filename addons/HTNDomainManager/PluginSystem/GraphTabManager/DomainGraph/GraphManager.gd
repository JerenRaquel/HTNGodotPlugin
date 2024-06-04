@tool
class_name HTNDomainGraph
extends GraphEdit

signal graph_altered

@onready var connection_handler: HTNConnectionHandler = $ConnectionHandler

var _manager: HTNDomainManager
var _root_node: GraphNode
var _selected_nodes: Array[GraphNode]
var _current_ID: int = 0

var nodes: Dictionary = {}

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager

	add_valid_connection_type(1, 1)
	add_valid_connection_type(2, 2)

	_root_node = _manager.node_spawn_menu.spawn_root()

func generate_node_key() -> StringName:
	var ID := _current_ID
	_current_ID += 1
	assert(
		_current_ID < 9223372036854775807,
		"YOU ABSOLUTE SANDWICH! HOW?! WHY?! ~Some angry chef most likely"
	)

	var key: String = "Sandwich_" + str(ID)

	while key in nodes:
		key = "Sandwich_" + str(_current_ID)

		_current_ID += 1
		assert(
			_current_ID < 9223372036854775807,
			"YOU ABSOLUTE SANDWICH! HOW?! WHY?! ~Some angry chef most likely"
		)

	return key	# This is the internal ID and you will love it >:3 ~ I was eating lol

func register_node(node: GraphNode, reg_key: StringName="") -> void:
	var node_key: StringName
	if reg_key != "":
		node_key = reg_key
	else:
		node_key = generate_node_key()

	#if node_key in nodes: return	# Is this needed (was bug node -> node)
	nodes[node_key] = node
	node.name = node_key
	graph_altered.emit()

func register_selected(node: GraphNode) -> void:
	if node in _selected_nodes: return
	_selected_nodes.push_back(node)

func unregister_selected(node: GraphNode) -> void:
	if node not in _selected_nodes: return
	_selected_nodes.erase(node)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	connection_handler.load_connection(from_node, from_port, to_node, to_port)

func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	_manager.node_spawn_menu.connect_node_data = {
		"from_node": from_node,
		"from_port": from_port,
		"release_position": release_position
	}
	_manager.node_spawn_menu.enable(connection_handler.get_output_port_type(from_node, from_port))

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)
	graph_altered.emit()

func _on_copy_nodes_request() -> void:
	pass # Replace with function body.

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	pass # Replace with function body.

func _on_paste_nodes_request() -> void:
	pass # Replace with function body.

func _on_popup_request(_position: Vector2) -> void:
	_manager.node_spawn_menu.enable()
