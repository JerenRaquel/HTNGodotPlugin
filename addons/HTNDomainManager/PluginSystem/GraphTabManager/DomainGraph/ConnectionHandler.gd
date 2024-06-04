@tool
class_name HTNConnectionHandler
extends Control

@onready var domain_graph: HTNDomainGraph = $".."

func get_output_port_type(node: StringName, port: int) -> int:
	var graph_node := (domain_graph.nodes[node] as GraphNode)
	var slot := graph_node.get_output_port_slot(port)
	return graph_node.get_output_port_type(slot)

func get_input_port_type(node: StringName, port: int) -> int:
	var graph_node := (domain_graph.nodes[node] as GraphNode)
	var slot := graph_node.get_input_port_slot(port)
	return graph_node.get_input_port_type(slot)

func is_connection_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	var from_type := get_output_port_type(from_node, from_port)
	var to_type := get_input_port_type(to_node, to_port)

	return domain_graph.is_valid_connection_type(from_type, to_type)

func load_connection(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if is_connection_valid(from_node, from_port, to_node, to_port):
		domain_graph.connect_node(from_node, from_port, to_node, to_port)
		domain_graph.graph_altered.emit()
