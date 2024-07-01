@tool
class_name HTNDomainSaver
extends Control

const DOMAIN_PATH := "res://addons/HTNDomainManager/Data/Domains/"
const GRAPH_SAVE_PATH := "res://addons/HTNDomainManager/Data/GraphSaves/"

@onready var file_manager: HTNFileManager = %FileManager
@onready var notification_handler: HTNNotificaionHandler = %NotificationHandler

func save(domain_graph: HTNDomainGraph) -> bool:
	print("Saving")
	var domain_file: HTNDomain = _save_to_domain_resource(domain_graph)
	if not _save_to_graph_file(domain_graph, domain_file):
		return false
	print(file_manager.HTN_REFERENCE_FILE["domains"])
	return true

func _save_to_domain_resource(domain_graph: HTNDomainGraph) -> HTNDomain:
	var domain_resource: HTNDomain
	var requires_write := false
	if domain_graph.domain_name in file_manager.HTN_REFERENCE_FILE["domains"]:
		domain_resource = file_manager.HTN_REFERENCE_FILE["domains"][domain_graph.domain_name]
	else:
		domain_resource = HTNDomain.new()
		requires_write = true

	domain_resource["required_domains"] = domain_graph.get_domain_links()
	domain_resource["required_tasks"] = domain_graph.get_task_keys()
	domain_resource["effects"] = _gather_effect_data(domain_graph)
	domain_resource["splits"] = _gather_split_data(domain_graph)
	domain_resource["methods"] = _gather_method_data(domain_graph)
	domain_resource["modules"] = _gather_module_data(domain_graph)

	if requires_write:
		return domain_resource	# Send the file to be saved
	return null

func _save_to_graph_file(domain_graph: HTNDomainGraph, domain_resource: HTNDomain) -> bool:
	var graph_save: HTNGraphSave
	if domain_resource == null:
		graph_save = ResourceLoader.load(file_manager.HTN_REFERENCE_FILE["graph_saves"][domain_graph.domain_name])
		if graph_save == null:
			notification_handler.send_error("Could not load domain save: '"+domain_graph.domain_name+"'")
			return false
	else:
		graph_save = HTNGraphSave.new()

	graph_save["root_key"] = domain_graph.root_key
	graph_save["connections"] = domain_graph.get_connection_list()
	for node_key: StringName in domain_graph.nodes.keys():
		graph_save["node_types"][node_key] = domain_graph.get_node_type(node_key)
		graph_save["node_positions"][node_key] = (domain_graph.nodes[node_key] as HTNBaseNode).position_offset
		graph_save["node_data"][node_key] = domain_graph.get_node_data(node_key)

	if domain_resource != null:
		var domain_path: String = DOMAIN_PATH + domain_graph.domain_name + ".tres"
		var result = ResourceSaver.save(domain_resource, domain_path)
		if result != OK:
			notification_handler.send_error("Building New Domain: '"+domain_graph.domain_name+"' Failed")
			return false

		var graph_save_path: String = GRAPH_SAVE_PATH + domain_graph.domain_name + ".tres"
		result = ResourceSaver.save(graph_save, graph_save_path)
		if result != OK:
			notification_handler.send_error("Building Graph Save: '"+domain_graph.domain_name+"' Failed")
			DirAccess.remove_absolute(domain_path)
			return false

		file_manager.HTN_REFERENCE_FILE["domains"][domain_graph.domain_name] = domain_resource
		file_manager.HTN_REFERENCE_FILE["graph_saves"][domain_graph.domain_name] = graph_save_path
	return true

func _gather_effect_data(domain_graph: HTNDomainGraph) -> Dictionary:
	var effect_data: Dictionary = {}
	for node_key: StringName in domain_graph.nodes.keys():
		var node: HTNBaseNode = domain_graph.nodes[node_key]
		if node is HTNApplicatorNode:
			#node.effect_data = { "WorldState" : { "TypeID", "Value" } }
			effect_data[node_key] = node.effect_data
	return effect_data

func _gather_split_data(domain_graph: HTNDomainGraph) -> Dictionary:
	var split_data: Dictionary = {}
	for node_key: StringName in domain_graph.nodes.keys():
		var node: HTNBaseNode = domain_graph.nodes[node_key]
		if node is HTNSplitterNode or node is HTNRootNode:
			var connected_node_keys: Array[StringName]\
				= HTNGlobals.connection_handler.get_connected_nodes_from_output(domain_graph, node_key)

			connected_node_keys.sort_custom(
				func(lhs: StringName, rhs: StringName) -> bool:
					var node_a: HTNMethodNode = domain_graph.nodes[lhs]
					var node_b: HTNMethodNode = domain_graph.nodes[rhs]

					return node_a.get_priority() > node_b.get_priority()
			)

			split_data[node_key] = connected_node_keys
	return split_data

func _gather_method_data(domain_graph: HTNDomainGraph) -> Dictionary:
	var method_data: Dictionary = {}
	for node_key: StringName in domain_graph.nodes.keys():
		var node: HTNBaseNode = domain_graph.nodes[node_key]
		if node is HTNMethodNode:
			method_data[node_key] = {
				#node.condition_data = {
					#"WorldState" = { "CompareID", "RangeID", "SingleID", "Value", "RangeInclusivity" }
				#}
				"method_data": node.condition_data,
				"task_chain": domain_graph.get_every_node_til_compound(node_key)
			}
	return method_data

func _gather_module_data(domain_graph: HTNDomainGraph) -> Dictionary:
	var module_data: Dictionary = {}
	for node_key: StringName in domain_graph.nodes.keys():
		var node: HTNBaseNode = domain_graph.nodes[node_key]
		# { module_node_key (StringName) : ["function_name", { ..module_data.. }] }
		if node is HTNModuleBaseNode:
			module_data[node_key] = [
				(node as HTNModuleBaseNode).get_module_function_name(),
				(node as HTNModuleBaseNode).get_data()
			]
	return module_data
