@tool
class_name HTNDomainGraph
extends GraphEdit

@onready var connection_handler: HTNConnectionHandler = $ConnectionHandler

var _manager: HTNDomainManager
var _root_node: GraphNode
var _current_ID: int = 0
var root_key: String
var domain_name: String = ""

var nodes: Dictionary = {}

func initialize(manager: HTNDomainManager, domain_tab_name: String) -> void:
	_manager = manager
	domain_name = domain_tab_name

	add_valid_connection_type(1, 1)
	add_valid_connection_type(2, 2)

	var data: Array = _manager.node_spawn_menu.spawn_root()
	_root_node = data[0]
	root_key = data[1]

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

func register_node(node: GraphNode, reg_key: StringName="") -> String:
	var node_key: StringName
	if reg_key != "":
		node_key = reg_key
	else:
		node_key = generate_node_key()

	nodes[node_key] = node
	node.name = node_key
	_manager.graph_altered.emit()
	return node_key

func clear() -> void:
	var node_keys: Array = nodes.keys()
	for node_key in node_keys:
		var node = nodes[node_key]
		if node is HTNRootNode: continue
		_delete_node(node)
	_current_ID = 1
	_manager.graph_altered.emit()

func get_node_offset_by_key(node_key: StringName) -> Dictionary:
	if node_key not in nodes: return {}

	var node = nodes[node_key]
	return {
		"offset": node.position_offset,
		"size": node.size
	}

func get_node_keys_with_meta() -> Dictionary:
	var data := {}
	for node_key: StringName in nodes.keys():
		var type: String
		if nodes[node_key] is HTNRootNode:
			type = "Root"
		elif nodes[node_key] is HTNApplicatorNode:
			type = "Applicator"
		elif nodes[node_key] is HTNCommentNode:
			type = "Comment"
		elif nodes[node_key] is HTNMethodNodeAlwaysTrue:
			type = "Always True Method"
		elif nodes[node_key] is HTNMethodNode:
			type = "Method"
		elif nodes[node_key] is HTNSplitterNode:
			type = "Splitter"
		elif nodes[node_key] is HTNTaskNode:
			type = "Task"

		data[node_key] = {
			"name": (nodes[node_key] as HTNBaseNode).get_node_name(),
			"type": type
		}
	return data

func _delete_node(node: HTNBaseNode) -> void:
	connection_handler.remove_connections(node)
	if not nodes.erase(node.name):
		push_error(node.name + " did not exist and is trying to erase.")
	node.free()

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
	_manager.graph_altered.emit()

func _on_delete_nodes_request(selected_nodes: Array[StringName]) -> void:
	while not selected_nodes.is_empty():
		var node_name: String = selected_nodes.pop_back()
		# Can't remove the root node
		var node = nodes[node_name]
		if node is HTNRootNode:
			continue

		_delete_node(node)
	_manager.graph_altered.emit()

func _on_copy_nodes_request() -> void:
	pass # Replace with function body.

func _on_paste_nodes_request() -> void:
	pass # Replace with function body.

func _on_popup_request(_position: Vector2) -> void:
	_manager.node_spawn_menu.enable()
