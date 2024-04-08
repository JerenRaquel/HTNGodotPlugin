@tool
class_name HTNGraphHandler
extends Control

signal graph_altered

var _manager: HTNDomainManager
var _selected_nodes: Array[GraphNode]
var _root_node: GraphNode
var _can_open_node_menu := true
var _current_ID := 0

var nodes: Dictionary
var graph_edit: GraphEdit
var node_spawn_menu: NodeSpawnMenu

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	graph_edit = %GraphEdit
	node_spawn_menu = %NodeSpawnMenu

	graph_edit.add_valid_connection_type(1, 1)
	graph_edit.add_valid_connection_type(2, 2)

	node_spawn_menu.initialize(manager)
	_root_node = node_spawn_menu.spawn_root()

func update() -> void:
	if _can_open_node_menu and Input.is_action_just_pressed("ui_accept"):
		if node_spawn_menu.visible:
			node_spawn_menu.hide()
			node_spawn_menu.connect_node_data.clear()
		else:
			_open_node_menu()
	elif not _selected_nodes.is_empty() and Input.is_action_just_pressed("ui_graph_delete"):
		_delete_nodes()

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

func load_node(node: PackedScene, node_key: StringName, node_position: Vector2, node_data) -> void:
	if node == node_spawn_menu.ROOT_NODE: return

	var node_instance: GraphNode = node.instantiate()
	graph_edit.add_child(node_instance)
	register_node(node_instance, node_key)
	node_instance.initialize(_manager)
	node_instance.load_data(node_data)
	node_instance.position_offset = node_position
	node_instance.node_selected.connect(func(): register_selected(node_instance))
	node_instance.node_deselected.connect(func(): unregister_selected(node_instance))

func wipe_nodes() -> void:
	_selected_nodes.clear()

	for node_key: StringName in nodes.keys():
		var node = nodes[node_key]
		if node is HTNRootNode: continue

		register_selected(node)

	_delete_nodes(false)
	_current_ID = 1
	_manager.not_saved = false
	_manager.validation_handler.clear_message()
	_manager.clear_button.disabled = true
	_manager.domain_panel.clear_graph()

func clear_node_colors() -> void:
	for node_key: StringName in nodes:
		(nodes[node_key] as GraphNode).modulate = Color.WHITE

func color_node_path(path: Array[StringName], is_valid: bool) -> void:
	for node_key: StringName in path:
		var node := nodes[node_key] as GraphNode
		if is_valid:
			node.modulate = Color("1aff00")
		else:
			node.modulate = Color("ff5f5f")

func is_connection_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	var from_type := get_output_port_type(from_node, from_port)
	var to_type := get_input_port_type(to_node, to_port)

	return graph_edit.is_valid_connection_type(from_type, to_type)

func get_node_offset(nickname: String) -> Dictionary:
	for node_key: StringName in nodes:
		var node = nodes[node_key]
		var node_name_stripped: String
		if node is HTNPrimitiveNode:
			node_name_stripped = node.get_task_name()
		else:
			node_name_stripped = node.get_node_name()\
				.replace("Applicator - ", "")\
				.replace("Compound Task - ", "")\
				.replace("Method - ", "")

		if node_name_stripped == nickname:
			return {
				"offset": node.position_offset,
				"size": node.size
			}
	return {}

func get_node_offset_by_key(node_key: StringName) -> Dictionary:
	if node_key not in nodes: return {}

	var node = nodes[node_key]
	return {
		"offset": node.position_offset,
		"size": node.size
	}

func get_output_port_type(node: StringName, port: int) -> int:
	var graph_node := (nodes[node] as GraphNode)
	var slot := graph_node.get_output_port_slot(port)
	return graph_node.get_output_port_type(slot)

func get_input_port_type(node: StringName, port: int) -> int:
	var graph_node := (nodes[node] as GraphNode)
	var slot := graph_node.get_input_port_slot(port)
	return graph_node.get_input_port_type(slot)

func has_connections_from_output(node_key: StringName) -> bool:
	for connection: Dictionary in graph_edit.get_connection_list():
		if connection["from_node"] == node_key: return true
	return false

func has_connections_from_input(node_key: StringName) -> bool:
	for connection: Dictionary in graph_edit.get_connection_list():
		if connection["to_node"] == node_key: return true
	return false

func get_root_key() -> StringName:
	return _root_node.name

func get_node_nickname(node_key: StringName, default_to_key:bool=true) -> String:
	var node: HTNBaseNode = nodes[node_key]
	var nick_name := node.get_node_name()
	if nick_name.is_empty():
		return node_key
	else:
		return nick_name

# return { node_key (StringName) : data (String) }
func get_comment_node_data() -> Dictionary:
	var data := {}

	for node_key: StringName in nodes:
		var node = nodes[node_key]
		if node is HTNCommentNode:
			data[node_key] = node.text_edit.text

	return data

func get_connected_nodes_from_output(node_key: StringName) -> Array[StringName]:
	var node_connection_data: Array[StringName] = []
	for connection: Dictionary in graph_edit.get_connection_list():
		var from_node_key: StringName = connection["from_node"]
		if from_node_key != node_key: continue

		node_connection_data.push_back(connection["to_node"])

	return node_connection_data

func get_connected_methods_from_output(node_key: StringName) -> Array[StringName]:
	var connected_node_data := get_connected_nodes_from_output(node_key)

	var node_connection_data: Array[StringName] = []
	for connection_node_key: StringName in connected_node_data:
		if nodes[connection_node_key] is HTNMethodNode:
			node_connection_data.push_back(connection_node_key)

	return node_connection_data

# return { node_key (StringName) : type (StringName) }
func get_every_node_type() -> Dictionary:
	var data := {}

	for node_key: StringName in nodes:
		if node_key not in data:
			var type: StringName
			var node = nodes[node_key]

			if node is HTNPrimitiveNode:
				data[node_key] = "Primitive"
			elif node is HTNRootNode:
				data[node_key] = "Root"
			elif node is HTNCompoundNode:
				data[node_key] = "Compound"
			elif node is HTNCommentNode:
				data[node_key] = "Comment"
			elif node is HTNMethodNodeAlwaysTrue:
				data[node_key] = "AlwaysTrueMethod"
			elif node is HTNMethodNode:
				data[node_key] = "Method"
			elif node is HTNApplicatorNode:
				data[node_key] = "Applicator"
			elif node is HTNDomainNode:
				data[node_key] = "Domain"
			else:
				data[node_key] = "Unknown"

	return data

# return { node_key (StringName) : position(Vector2) }
func get_every_node_position() -> Dictionary:
	var data := {}

	for node_key: StringName in nodes:
		if node_key not in data:
			data[node_key] = nodes[node_key].position_offset

	return data

# return { node_key (StringName) : task_name (StringName) }
func get_every_primitive() -> Dictionary:
	var primitives: Dictionary = {}

	for node_key: StringName in nodes:
		if nodes[node_key] is HTNPrimitiveNode and node_key not in primitives:
			primitives[node_key] = nodes[node_key].get_task_name()

	return primitives

# return [ node_key (StringName)... ]
func get_every_compound() -> Array[StringName]:
	var compounds: Array[StringName] = []

	for node_key: StringName in nodes:
		if nodes[node_key] is HTNCompoundNode and node_key not in compounds:
			compounds.push_back(node_key)

	return compounds

# return { node_key (StringName) : task_name (StringName) }
func get_every_domain() -> Dictionary:
	var data: Dictionary = {}

	for node_key: StringName in nodes:
		if nodes[node_key] is HTNDomainNode and node_key not in data:
			var domain_name: String = nodes[node_key].get_selected_domain_name()
			if domain_name.is_empty(): continue

			data[node_key] = domain_name

	return data

func get_every_node_til_compound(node_key: String) -> Array[StringName]:
	var task_chain: Array[StringName] = []
	_get_every_node_til_compound_helper(node_key, task_chain)

	return task_chain

func load_connection(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if is_connection_valid(from_node, from_port, to_node, to_port):
		graph_edit.connect_node(from_node, from_port, to_node, to_port)
		graph_altered.emit()

func _get_every_node_til_compound_helper(current_key: String, task_chain: Array[StringName]) -> void:
	var connected_nodes := get_connected_nodes_from_output(current_key)

	# We're done -- Stopped at dead end
	if connected_nodes.size() == 0:
		return

	if connected_nodes.size() > 1:
		push_error(current_key + " has multiple output connections.")
		return

	var connected_node := connected_nodes[0]
	# We're done -- Stopped at compound
	if nodes[connected_node] is HTNCompoundNode:
		task_chain.push_back(connected_node)
		return

	# We're done -- Stopped before recurion
	if connected_node in task_chain: return

	# We just keep on going
	task_chain.push_back(connected_node)
	_get_every_node_til_compound_helper(connected_node, task_chain)

func _open_node_menu(port_type: int=-1) -> void:
	node_spawn_menu.show()
	node_spawn_menu.enable_usable_nodes(port_type)
	node_spawn_menu.global_position = get_global_mouse_position()

func _delete_nodes(emit_altered_signal:bool=true) -> void:
	while not _selected_nodes.is_empty():
		var node: GraphNode = _selected_nodes.pop_back()
		_remove_connections(node)
		if not nodes.erase(node.name):
			push_error(node.name + " did not exist and is trying to erase.")
		node.free()
	if emit_altered_signal: graph_altered.emit()

func _remove_connections(node: GraphNode) -> void:
	for connection in graph_edit.get_connection_list():
		if connection.to_node == node.name or connection.from_node == node.name:
			graph_edit.disconnect_node(
				connection.from_node,
				connection.from_port,
				connection.to_node,
				connection.to_port
			)
	graph_altered.emit()

func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	load_connection(from_node, from_port, to_node, to_port)

func _on_graph_edit_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	node_spawn_menu.connect_node_data = {
		"from_node": from_node,
		"from_port": from_port,
		"release_position": release_position
	}
	_open_node_menu(get_output_port_type(from_node, from_port))

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	graph_altered.emit()

func _on_graph_edit_focus_entered() -> void:
	_can_open_node_menu = true

func _on_graph_edit_focus_exited() -> void:
	_can_open_node_menu = false

func _on_clear_button_pressed() -> void:
	if _manager.not_saved:
		_manager.warning_screen.open(
			"This will clear the entire graph.\nYou have unsaved changes.\nAre you sure?",
			func(): wipe_nodes(),
			Callable()
		)
	else:
		wipe_nodes()

func _on_graph_tools_toggle_toggled(toggled_on: bool) -> void:
	graph_edit.show_menu = toggled_on
