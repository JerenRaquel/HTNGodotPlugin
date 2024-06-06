@tool
class_name HTNTabGraphManager
extends TabContainer

const GRAPH_TAB = preload("res://addons/HTNDomainManager/PluginSystem/GraphTabManager/GraphTab/graph_tab.tscn")
const TRASH = preload("res://addons/HTNDomainManager/PluginSystem/Icons/Trash.svg")

var _manager: HTNDomainManager
var _regex: RegEx
var _empty_tab_idx: int

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	_regex = RegEx.new()
	_regex.compile("[^A-Za-z0-9]")
	_create_new_tab()

func validate_tab_creation(domain_name: String) -> bool:
	if domain_name[0].is_valid_int(): return false
	var result = _regex.search(domain_name)
	if result:
		print("Alphanumeric characters only! Found: [", result.get_string(0), "]")
		return false

	if _manager.file_manager.check_if_domain_name_exists(domain_name):
		return false

	for child: Control in get_children():
		if child.name == domain_name:
			return false

	return true

func _create_new_tab() -> void:
	var tab_instance := GRAPH_TAB.instantiate()
	tab_instance.tab_created.connect(
		func(graph: HTNDomainGraph) -> void:
			_manager.current_graph = graph
			graph.initialize(_manager, tab_instance.get_domain_name())
			_manager.graph_altered.emit()
			set_tab_button_icon(current_tab, TRASH)
			_create_new_tab()
	)
	add_child(tab_instance)
	_empty_tab_idx += 1

func _on_tab_changed(tab: int) -> void:
	var tab_ctx: HTNGraphTab = get_tab_control(tab)
	_manager.current_graph = tab_ctx.domain_graph
	_manager.graph_tab_changed.emit()

func _on_tab_button_pressed(tab: int) -> void:
	_manager.graph_altered.emit()
	# CRITICAL: Add tab deletion
