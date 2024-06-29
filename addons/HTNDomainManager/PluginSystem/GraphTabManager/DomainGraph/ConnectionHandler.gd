@tool
class_name HTNConnectionHandler
extends Control

@onready var domain_graph: HTNDomainGraph = $".."

func remove_connections(node: GraphNode) -> void:
	for connection in domain_graph.get_connection_list():
		if connection.to_node == node.name or connection.from_node == node.name:
			domain_graph.disconnect_node(
				connection.from_node,
				connection.from_port,
				connection.to_node,
				connection.to_port
			)
	HTNGlobals.graph_altered.emit()
	domain_graph.is_saved = false

func get_output_port_type(node: StringName, port: int) -> int:
	var graph_node := (domain_graph.nodes[node] as HTNBaseNode)
	var slot := graph_node.get_output_port_slot(port)
	return graph_node.get_output_port_type(slot)

func get_input_port_type(node: StringName, port: int) -> int:
	var graph_node := (domain_graph.nodes[node] as HTNBaseNode)
	var slot := graph_node.get_input_port_slot(port)
	return graph_node.get_input_port_type(slot)

func is_connection_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	var from_type := get_output_port_type(from_node, from_port)
	var to_type := get_input_port_type(to_node, to_port)

	return domain_graph.is_valid_connection_type(from_type, to_type)

func load_connection(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if not is_connection_valid(from_node, from_port, to_node, to_port): return
	domain_graph.connect_node(from_node, from_port, to_node, to_port)
	HTNGlobals.graph_altered.emit()
	domain_graph.is_saved = false

func get_connected_nodes_from_output(node_key: StringName) -> Array[StringName]:
	var node_connection_data: Array[StringName] = []
	for connection: Dictionary in domain_graph.get_connection_list():
		var from_node_key: StringName = connection["from_node"]
		if from_node_key != node_key: continue

		node_connection_data.push_back(connection["to_node"])

	return node_connection_data

func has_connections_from_input(node_key: StringName) -> bool:
	for connection: Dictionary in domain_graph.get_connection_list():
		if connection["to_node"] == node_key: return true
	return false

func has_connections_from_output(node_key: StringName) -> bool:
	for connection: Dictionary in domain_graph.get_connection_list():
		if connection["from_node"] == node_key: return true
	return false
