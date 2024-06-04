@tool
extends Control

const DOMAIN_GRAPH = preload("res://addons/HTNDomainManager/PluginSystem/GraphTabManager/DomainGraph/domain_graph.tscn")

signal tab_created(graph: HTNDomainGraph)

@onready var empty_fields_container: VBoxContainer = %EmptyFieldsContainer
@onready var domain_line_edit: LineEdit = %DomainLineEdit
@onready var create_button: Button = %CreateButton

func _on_create_button_pressed() -> void:
	# No name given
	if get_domain_name().is_empty(): return

	# Check if tab was already created
	if not get_parent().validate_tab_creation(get_domain_name()):
		return

	name = get_domain_name()
	var domain_graph_instance := DOMAIN_GRAPH.instantiate()
	add_child(domain_graph_instance)
	get_parent()._manager.graph_tool_bar_toggled.connect(
		func(state: bool) -> void:
			domain_graph_instance.show_menu = state
	)
	tab_created.emit(domain_graph_instance)
	empty_fields_container.queue_free()

func get_domain_name() -> String:
	if domain_line_edit != null:
		return domain_line_edit.text.to_pascal_case()
	else:
		return name
