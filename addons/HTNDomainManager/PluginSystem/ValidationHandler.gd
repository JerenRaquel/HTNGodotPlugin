@tool
class_name HTNNodeValidationHandler
extends Control

enum MessageType { DEFAULT, OK, WARNING, ERROR }

const DEFAULT_COLOR := Color("e0e0e0")
const OK_COLOR := Color("65bcb2")
const WARNING_COLOR := Color("fedc65")
const ERROR_COLOR := Color("ff5f5f")

#region New Code Region
const EMPTY_CONNECTIONS := "There are no connections."
const NO_TASK_CONNECTIONS := "This node has no task connection(s)."
const NO_METHOD_CONNECTIONS := "This node has no method connections."
const ONE_TASK_CONNECTION_REQURIED := "This node requries 1 task connected to output."
const OVER_ONE_CONNECTION := "There are more than one connection."
const OVER_ONE_ALWAYS_TRUE_METHOD_CONNECTION := "There are more than one Method Node - Always True."
const FAILED_FILE_WRITE := "Couldn't write to file. Halting futher writting"
const INVALID_DOMAIN_NAME := "Domain name is empty."
const GOTO_FAILED := "Can't find node. Missing a nickname?"
const EMPTY_FIELD := "Input field is empty."
const SIM_INVALID_STATES := "There is at least one invalid world state."

#endregion

@onready var timer: Timer = $"../Timer"
@onready var build_notice: Label = %BuildNotice

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	timer.timeout.connect( func(): send_message("", MessageType.DEFAULT) )

func send_error_generic(error_message: String, fade: bool=false) -> void:
	send_message(error_message, MessageType.ERROR, fade)

func send_error_message(node_name: String, error_message: String) -> void:
	send_message("'" + node_name + "' is invalid::" + error_message, MessageType.ERROR)

func send_error_message_fade(node_name: String, error_message: String) -> void:
	send_message("'" + node_name + "' is invalid::" + error_message, MessageType.ERROR, true)

func send_message(message: String, type: MessageType, start_timer: bool=false) -> void:
	if timer.time_left > 0: timer.stop()

	build_notice.text = message
	match type:
		MessageType.DEFAULT:
			if _manager.not_saved:
				build_notice.text = "Unsaved Changes"
				build_notice.label_settings.font_color = WARNING_COLOR
			else:
				build_notice.label_settings.font_color = DEFAULT_COLOR
		MessageType.OK:
			build_notice.label_settings.font_color = OK_COLOR
		MessageType.WARNING:
			build_notice.label_settings.font_color = WARNING_COLOR
		MessageType.ERROR:
			build_notice.label_settings.font_color = ERROR_COLOR
		_:
			push_warning("Sent an invalid message code: " + str(type))

	if start_timer: timer.start()

func validate_graph(domain_name: String) -> bool:
	# Validate that there are any connections....
	# I know who you are. I put this in for you... ._.
	if not validate_there_are_any_connections(domain_name): return false

	if not validate_node_data(): return false

	# Validate each node's rules (listed above function declaration)
	if not validate_node_connections(_manager.graph_handler): return false

	# Save Primitive Node Data to File
	if not save_primitive_node_data(): return false

	# Save graph to domain file
	if not _manager.domain_builder.write_domain_file(domain_name): return false

	return true

func validate_there_are_any_connections(domain_name: String) -> bool:
	var connection_list := _manager.graph_handler.graph_edit.get_connection_list()

	if connection_list.is_empty():
		if domain_name.is_empty() or domain_name == "":
			send_error_message("Domain", EMPTY_CONNECTIONS)
		else:
			send_error_message(domain_name, EMPTY_CONNECTIONS)
		return false
	return true

func validate_node_data() -> bool:
	for node_key: String in _manager.graph_handler.nodes:
		var node := (_manager.graph_handler.nodes[node_key] as HTNBaseNode)
		if node.is_queued_for_deletion(): continue

		var error_message := node.validate_self()
		if error_message != "":
			var node_name := node.get_node_name()
			if node_name == "": node_name = node_key
			send_error_message(node_name, error_message)
			return false
	return true

# Validate each node's rules
#	- Input:
#		- Compound Node:
#			- At least 1 task connection
#		- Primitive Node:
#			- At least 1 task connection
#		- Method Nodes:
#			- At least 1 task connection
#	- Output:
#		- Root Node and Compound Node:
#			- There can only be one Always-True-Method connected.
#			- Must have output connections (at least 1)
#			- Connected method pritories have to be unique
#		- Primitive Node:
#			- Can only have at most one output connection
#		- Method Nodes:
#			- Requires 1 output connection
#		- Applicator:
#			- Requires 1 output connection
func validate_node_connections(graph_handler: HTNGraphHandler) -> bool:
	for node_key: StringName in graph_handler.nodes:
		var connected_node_connection_names: Array[StringName] =\
			graph_handler.get_connected_nodes_from_output(node_key)
		var node = graph_handler.nodes[node_key]
		var node_name: String = node.get_node_name()
		if node_name.is_empty() or node_name == "": node_name = node_key

		# We ignore comments here lmao
		if node is HTNCommentNode: continue

		if node is HTNRootNode or node is HTNCompoundNode:
			if not _validate_root_and_compound_nodes(
				graph_handler,
				node_key, node_name,
				connected_node_connection_names
			): return false
		elif node is HTNPrimitiveNode:
			# Check for at least one task output connection
			if graph_handler.get_connected_nodes_from_output(node_key).size() > 1:
				send_error_message(node_name, OVER_ONE_CONNECTION)
				return false
			# Check for any amount of task input connections
			if not graph_handler.has_connections_from_input(node_key):
				send_error_message(node_name, NO_TASK_CONNECTIONS)
				return false
		elif node is HTNMethodNode: # Should cover Always True
			# Check for ONLY one task output connection
			if graph_handler.get_connected_nodes_from_output(node_key).size() != 1:
				send_error_message(node_name, ONE_TASK_CONNECTION_REQURIED)
				return false
			# Check for any amount of task input connections
			if not graph_handler.has_connections_from_input(node_key):
				send_error_message(node_name, NO_TASK_CONNECTIONS)
				return false
		elif node is HTNApplicatorNode:
			# Check for ONLY one task output connection
			if graph_handler.get_connected_nodes_from_output(node_key).size() != 1:
				send_error_message(node_name, ONE_TASK_CONNECTION_REQURIED)
				return false
	return true

func save_primitive_node_data() -> bool:
	for node_key: String in _manager.graph_handler.nodes:
		var node = _manager.graph_handler.nodes[node_key]
		if not node is HTNPrimitiveNode: continue

		var prim_node: HTNPrimitiveNode = (node as HTNPrimitiveNode)
		if not prim_node.write_data():
			var node_name: String = prim_node.get_node_name()
			send_error_message(node_name, FAILED_FILE_WRITE)
			return false
	return true

func _validate_root_and_compound_nodes(
		graph_handler: HTNGraphHandler, node_key: StringName, node_name: String,
		connected_node_connection_names: Array[StringName]) -> bool:
	# Check for any amount of method output connections
	if not graph_handler.has_connections_from_output(node_key):
		send_error_message(node_name, NO_METHOD_CONNECTIONS)
		return false

	# Check for >=1 task connection
	if graph_handler.nodes[node_key] is HTNCompoundNode:
		if not graph_handler.has_connections_from_input(node_key):
			send_error_message(node_name, NO_TASK_CONNECTIONS)
			return false

	var found_always_true := false
	var priority_values := {}
	# Evaluate connected methods
	for connection_name: StringName in connected_node_connection_names:
		var node = graph_handler.nodes[connection_name]

		# Look for more than one always true method connection
		if node is HTNMethodNodeAlwaysTrue:
			if not found_always_true:
				found_always_true = true
			else:
				send_error_message(node_name, OVER_ONE_ALWAYS_TRUE_METHOD_CONNECTION)
				return false

		var priority := (node as HTNMethodNode).get_priority()
		var connected_node_name: String = node.get_node_name()
		if connected_node_name == "": connected_node_name = connection_name

		# Check for duplicate priority value
		if priority in priority_values.values():
			var format_string := "%s has the same priority of these nodes [ "
			var error_message := format_string % connected_node_name

			for key: StringName in priority_values.keys():
				if priority_values[key] == priority:
					error_message += key

			send_error_message(connected_node_name, error_message + " ]")
			return false
		else:
			priority_values[connected_node_name] = priority

	return true
