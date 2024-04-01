@tool
class_name HTNDomainBuilder
extends Control
const DOMAIN_PATH := "res://addons/HTNDomainManager/HTNGameLibrary/Data/Domains/"
const GRAPH_SAVE_PATH := "res://addons/HTNDomainManager/HTNGameLibrary/Data/GraphSaves/"
var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager

func write_domain_file(file_name: String) -> bool:
	# Check if folder exists -- It should since its part of the plugin
	if not DirAccess.dir_exists_absolute(DOMAIN_PATH):
		_manager.validation_handler.send_error_generic(
			"File path doesn't exist::" + DOMAIN_PATH
		)
		return false

	if not DirAccess.dir_exists_absolute(GRAPH_SAVE_PATH):
		_manager.validation_handler.send_error_generic(
			"File path doesn't exist::" + GRAPH_SAVE_PATH
		)
		return false

	# Create new file
	var resource: HTNDomain
	if FileAccess.file_exists(DOMAIN_PATH + file_name + ".tres"):
		resource = load(DOMAIN_PATH + file_name + ".tres")
	else:
		resource = HTNDomain.new()

	# Gather and record data
	_clear_previous_data(resource)
	_gather_data(resource)

	# Save
	var error_code := ResourceSaver.save(resource, DOMAIN_PATH + file_name + ".tres")
	if error_code != OK:
		push_error(error_code)
		return false

	var save_file: HTNGraphSave
	if FileAccess.file_exists(GRAPH_SAVE_PATH + file_name + ".tres"):
		save_file = load(GRAPH_SAVE_PATH + file_name + ".tres")
	else:
		save_file = HTNGraphSave.new()

	# Record node positions
	save_file["root_key"] = _manager.graph_handler.get_root_key()
	# { node_key (StringName) : task_name (StringName) }
	save_file["primitives"] = _manager.graph_handler.get_every_primitive()
	# Connections of the different nodes
	save_file["connections"] = _manager.graph_handler.graph_edit.get_connection_list()
	# return { node_key (StringName) : type (StringName) }
	save_file["node_types"] = _manager.graph_handler.get_every_node_type()
	# { node_key (StringName) : position(Vector2) }
	save_file["node_positions"] = _manager.graph_handler.get_every_node_position()

	# Write Node MetaData
	# { node_key (StringName) : data (Dictionary) }
	save_file["node_data"] = {}
	# Primitive Data - Task Name
	save_file["node_data"].merge(save_file["primitives"], true)
	# Compound Data - Nickname
	save_file["node_data"].merge(_grab_compound_nicknames(resource), true)
	# Comment Data - Comment
	save_file["node_data"].merge(_manager.graph_handler.get_comment_node_data(), true)
	# Method Data - The whole thingy
	save_file["node_data"].merge(_grab_method_data(resource), true)
	# Applicator Data - Effect Data
	save_file["node_data"].merge(resource["effects"], true)

	# Save
	error_code = ResourceSaver.save(save_file, GRAPH_SAVE_PATH + file_name + ".tres")
	if error_code != OK:
		push_error(error_code)
		return false

	return true

func load_domain_file(file_name: String) -> bool:
	# Check if folder exists -- It should since its part of the plugin
	var path := GRAPH_SAVE_PATH + file_name + ".tres"
	if not FileAccess.file_exists(path):
		_manager.validation_handler.send_error_generic(
			"File path doesn't exist::" + path
		)
		return false

	var save_file: HTNGraphSave = ResourceLoader.load(path)
	if not save_file:
		_manager.validation_handler.send_error_generic(
			"File could not be loaded::" + path
		)
		return false

	# Reconstruct
	# Clear current canvas
	_manager.graph_handler.wipe_nodes()

	# Create nodes and load data
	for node_key: StringName in save_file["node_positions"]:
		if node_key == save_file["root_key"]: continue

		var node_type: String = save_file["node_types"][node_key]
		var node_position: Vector2 = save_file["node_positions"][node_key]

		var data = save_file["node_data"][node_key]
		var node: PackedScene
		match node_type:
			"Primitive":
				node = _manager.graph_handler.node_spawn_menu.PRIMITIVE_NODE
			"Root":
				continue	# Root already exists
			"Compound":
				node = _manager.graph_handler.node_spawn_menu.COMPOUND_NODE
			"Comment":
				node = _manager.graph_handler.node_spawn_menu.COMMENT_NODE
			"AlwaysTrueMethod":
				node = _manager.graph_handler.node_spawn_menu.ALWAYS_TRUE_METHOD
			"Method":
				node = _manager.graph_handler.node_spawn_menu.METHOD_NODE
			"Applicator":
				node = _manager.graph_handler.node_spawn_menu.APPLICATOR_NODE
			_: continue	# Don't know, don't care lmao

		_manager.graph_handler.load_node(node, node_key, node_position, data)

	# Connect nodes
	for connection: Dictionary in save_file["connections"]:
		#{from_node: StringName, from_port: int, to_node: StringName, to_port: int}
		_manager.graph_handler.load_connection(
			connection["from_node"],
			connection["from_port"],
			connection["to_node"],
			connection["to_port"]
		)

	return true

func _clear_previous_data(resource: HTNDomain) -> void:
	resource["required_primitives"].clear()
	resource["compounds"].clear()
	resource["methods"].clear()
	resource["effects"].clear()

func _gather_data(resource: HTNDomain) -> void:
	var root_key: StringName = _manager.graph_handler.get_root_key()
	resource["root_key"] = root_key
	# Manual root node insert
	var root_name = _manager.graph_handler.nodes[root_key].get_node_name()
	if root_name == "": root_name = root_key
	var method_keys := _manager.graph_handler.get_connected_methods_from_output(root_key)
	# No need to sort a single size array
	if method_keys.size() > 1:
		# Sort based on priority
		method_keys.sort_custom(_sort_method_keys)
	resource["compounds"][root_key] = {
		"nick_name": root_name,
		"method_branches": method_keys
	}

	# Begin the tree decsent
	_compile_method_paths_into_domain(method_keys, resource)

func _compile_method_paths_into_domain(method_keys: Array[StringName], resource: HTNDomain) -> void:
	for method_key: StringName in method_keys:
		if method_key in resource["methods"]: continue
		_handle_method_key(method_key, resource)

func _handle_method_key(method_key: StringName, resource: HTNDomain) -> void:
	var data: Array[StringName] = _manager.graph_handler.get_every_node_til_compound(method_key)
	var task_chain: Array[StringName] = []
	for node_key: StringName in data:
		var node = _manager.graph_handler.nodes[node_key]
		if node is HTNCompoundNode:
			_handle_compound_node(node.get_node_name(), node_key, task_chain, resource)
		elif node is HTNPrimitiveNode:
			_handle_primitive_node(node.get_node_name(), task_chain, resource)
		elif node is HTNApplicatorNode:
			_handle_applicator_node(node, node_key, task_chain, resource)

	resource["methods"][method_key] = {
		"nick_name": (_manager.graph_handler.nodes[method_key] as HTNMethodNode).get_node_name(),
		"method_data": (_manager.graph_handler.nodes[method_key] as HTNMethodNode).condition_data,
		"task_chain": task_chain
	}

func _handle_applicator_node(node: HTNApplicatorNode, node_key: StringName, task_chain: Array[StringName], resource: HTNDomain) -> void:
	var stripped_name: String = node.get_node_name()
	stripped_name = stripped_name.replace("Applicator - ", "")

	task_chain.push_back(node_key)
	if node_key in resource["effects"]: return
	resource["effects"][node_key] = {
		"nick_name": stripped_name,
		"data": node.effect_data
	}

func _handle_primitive_node(node_name: String, task_chain: Array[StringName], resource: HTNDomain) -> void:
	var stripped_name: String = node_name
	stripped_name = stripped_name.substr("Primitive - ".length())
	task_chain.push_back(stripped_name)

	# Record the task resource file path
	var resource_path: String = _manager.serializer.get_resource_path_from_name(stripped_name)
	if resource_path == "":
		_manager.validation_handler.send_error_generic(
			"File path doesn't exist for " + stripped_name
		)
	if stripped_name in resource["required_primitives"]: return
	resource["required_primitives"][stripped_name] = resource_path

func _handle_compound_node(
		node_name: String, compound_key: StringName, task_chain: Array[StringName],
		resource: HTNDomain) -> void:
	var compound_name = node_name
	if compound_name == "": compound_name = compound_key

	task_chain.push_back(compound_key)
	if compound_key in resource["compounds"]: return

	var method_keys := _manager.graph_handler.get_connected_methods_from_output(compound_key)
	resource["compounds"][compound_key] = {
		"nick_name": compound_name,
		"method_branches": method_keys
	}
	# No need to sort a single value array
	if method_keys.size() > 1:
		# Sort based on priority
		method_keys.sort_custom(_sort_method_keys)

	# We dig deeper
	_compile_method_paths_into_domain(method_keys, resource)

func _sort_method_keys(method_a: StringName, method_b: StringName) -> bool:
	var node_a: HTNMethodNode = _manager.graph_handler.nodes[method_a]
	var node_b: HTNMethodNode = _manager.graph_handler.nodes[method_b]

	return node_a.get_priority() > node_b.get_priority()

func _grab_compound_nicknames(resource: HTNDomain) -> Dictionary:
	var data := {}

	for node_key: StringName in resource["compounds"]:
		data[node_key] = resource["compounds"][node_key]["nick_name"]

	return data

func _grab_method_data(resource: HTNDomain) -> Dictionary:
	var data := {}

	for node_key: StringName in resource["methods"]:
		data[node_key] = {
			"nick_name": resource["methods"][node_key].get("nick_name", ""),
			"condition_data": resource["methods"][node_key]["method_data"],
			"priority": (_manager.graph_handler.nodes[node_key] as HTNMethodNode).get_priority()
		}

	return data
