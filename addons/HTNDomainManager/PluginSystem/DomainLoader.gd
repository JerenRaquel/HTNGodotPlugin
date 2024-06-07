@tool
class_name HTNDomainLoader
extends Control

const GRAPH_SAVE_PATH := "res://addons/HTNDomainManager/Data/GraphSaves/"
const PRELOADED_GRAPH_TAB = preload("res://addons/HTNDomainManager/PluginSystem/GraphTabManager/PreloadedGraphTab/preloaded_graph_tab.tscn")

@onready var file_manager: HTNFileManager = %FileManager
@onready var tab_container: HTNTabGraphManager = %TabContainer
@onready var node_spawn_menu: HTNNodeSpawnMenu = %NodeSpawnMenu

#graph_save["root_key"] = domain_graph.root_key
#graph_save["connections"] = domain_graph.get_connection_list()
#for node_key: StringName in domain_graph.nodes.keys():
	#graph_save["node_types"][node_key] = domain_graph.get_node_type(node_key)
	#graph_save["node_positions"][node_key] = (domain_graph.nodes[node_key] as HTNBaseNode).position_offset
	#graph_save["node_data"][node_key] = domain_graph.get_node_data(node_key)

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager

func load_domain(domain_name: String) -> bool:
	var graph_save_file: HTNGraphSave = ResourceLoader.load(GRAPH_SAVE_PATH + domain_name + ".tres")
	if graph_save_file == null:
		return false

	var new_graph: HTNPreloadedGraphTab = PRELOADED_GRAPH_TAB.instantiate()
	tab_container.add_child(new_graph)
	tab_container.move_child(new_graph, 0)
	while tab_container.current_tab > 0:
		tab_container.select_previous_available()

	var domain_graph: HTNDomainGraph = new_graph.load_data(domain_name)
	_manager.current_graph = domain_graph
	domain_graph.initialize(_manager, new_graph, domain_name)

	# Create nodes and load data
	for node_key: StringName in graph_save_file["node_positions"]:
		if node_key == graph_save_file["root_key"]: continue

		var node_type: String = graph_save_file["node_types"][node_key]
		var node_position: Vector2 = graph_save_file["node_positions"][node_key]

		var node_data = graph_save_file["node_data"][node_key]
		var node: PackedScene
		match node_type:
			"Task":
				node = node_spawn_menu.HTN_TASK_NODE
			"Root":
				continue	# Root already exists
			"Splitter":
				node = node_spawn_menu.HTN_SPLITTER_NODE
			"Domain":
				node = node_spawn_menu.HTN_DOMAIN_NODE
			"Comment":
				node = node_spawn_menu.HTN_COMMENT_NODE
			"Always True Method":
				node = node_spawn_menu.HTN_ALWAYS_TRUE_METHOD_NODE
			"Method":
				node = node_spawn_menu.HTN_METHOD_NODE
			"Applicator":
				node = node_spawn_menu.HTN_APPLICATOR_NODE
			_: continue	# Don't know, don't care lmao
		new_graph.domain_graph.load_node(node, node_key, node_position, node_data)

	# Connect nodes
	for connection: Dictionary in graph_save_file["connections"]:
		#{from_node: StringName, from_port: int, to_node: StringName, to_port: int}
		new_graph.domain_graph.connection_handler.load_connection(
			connection["from_node"],
			connection["from_port"],
			connection["to_node"],
			connection["to_port"]
		)

	return true
