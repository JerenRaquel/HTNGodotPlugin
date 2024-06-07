@tool
class_name HTNGraphTab
extends Control

const DOMAIN_GRAPH = preload("res://addons/HTNDomainManager/PluginSystem/GraphTabManager/DomainGraph/domain_graph.tscn")

signal tab_created(graph: HTNDomainGraph)

var domain_graph: HTNDomainGraph = null
var is_empty := true

func get_domain_name() -> String:
	if %DomainLineEdit != null:
		return %DomainLineEdit.text.to_pascal_case()
	else:
		return name.replace("*", "")

func tab_save_state(state: bool) -> void:
	if state:
		name = name.replace("*", "")
	elif not state and not name.ends_with("*"):
		name += "*"

func _on_create_button_pressed() -> void:
	# No name given
	if get_domain_name().is_empty(): return

	# Check if tab was already created
	if not get_parent().validate_tab_creation(get_domain_name()):
		return

	name = get_domain_name() + "*"
	domain_graph = DOMAIN_GRAPH.instantiate()
	add_child(domain_graph)
	get_parent()._manager.graph_tool_bar_toggled.connect(
		func(state: bool) -> void:
			domain_graph.show_menu = state
	)
	tab_created.emit(domain_graph)
	%EmptyFieldsContainer.queue_free()
	is_empty = false
