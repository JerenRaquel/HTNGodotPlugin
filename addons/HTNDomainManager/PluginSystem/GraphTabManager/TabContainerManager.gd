@tool
class_name HTNTabGraphManager
extends TabContainer

const GRAPH_TAB = preload("res://addons/HTNDomainManager/PluginSystem/GraphTabManager/GraphTab/graph_tab.tscn")
const TRASH = preload("res://addons/HTNDomainManager/PluginSystem/Icons/Trash.svg")

var _manager: HTNDomainManager
var _empty_tab_idx: int

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	_create_new_tab()

func validate_tab_creation(domain_name: String) -> bool:
	for child: Control in get_children():
		if child.name == domain_name:
			return false

	# CRITICAL: Check if domain already exists

	return true

func _create_new_tab() -> void:
	var tab_instance := GRAPH_TAB.instantiate()
	tab_instance.tab_created.connect(
		func(graph: HTNDomainGraph) -> void:
			_manager.current_graph = graph
			graph.initialize(_manager)
			set_tab_button_icon(current_tab, TRASH)
			_create_new_tab()
	)
	add_child(tab_instance)
	_empty_tab_idx += 1

func _on_tab_changed(tab: int) -> void:
	pass # Replace with function body.

func _on_tab_button_pressed(tab: int) -> void:
	pass # Replace with function body.
