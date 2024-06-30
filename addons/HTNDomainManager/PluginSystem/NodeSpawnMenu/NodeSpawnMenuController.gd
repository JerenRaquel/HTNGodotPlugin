@tool
class_name HTNNodeSpawnMenu
extends Control

## Node Data
#Color Code:
#- Compound/Root <-> Methods: 4f8fba - Blue
#- Tasks <-> Tasks: 468232 - Green
#
#IDs:
#- Compound/Root <-> Methods: 1
#- Tasks <-> Tasks: 2

const TREE_DROP_BUTTON = preload("res://addons/HTNDomainManager/PluginSystem/Components/Tree/TreeDropButton/tree_drop_button.tscn")
const ON_PORT_BLUE: Array[String] = ["Method", "AlwaysTrueMethod"]
const ON_PORT_GREEN: Array[String] = ["Task", "Domain", "Applicator", "Splitter"]

@export var _manager: HTNDomainManager

@onready var node_buttons: VBoxContainer = %NodeButtons

var _mouse_local_position: Vector2
var can_be_opened := false
var connect_node_data: Dictionary = {}

func _ready() -> void:
	if not Engine.is_editor_hint():
		set_process_unhandled_input(false)
		return

	_add_nodes_to_menu()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventAction or event is InputEventKey:
		if visible:
			hide()

func enable(port_type: int=-1) -> void:
	if visible and port_type == -1:
		hide()
		return

	match port_type:
		-1, 0:
			_show_all()
		1:
			for tree_drop: TreeDropButton in node_buttons.get_children():
				tree_drop.filter(ON_PORT_BLUE)
		2:
			for tree_drop: TreeDropButton in node_buttons.get_children():
				tree_drop.filter(ON_PORT_GREEN)
		_:
			_hide_all()
	show()
	global_position = get_global_mouse_position()

func spawn_root(manager: HTNDomainManager) -> Array:
	assert(manager.current_graph != null, "Current Graph is NULL")

	var root_instance: HTNRootNode = HTNGlobals.NODES["Root"].instantiate()
	manager.current_graph.add_child(root_instance)
	root_instance.initialize(manager)
	var root_key: String = manager.current_graph.register_node(root_instance)
	_set_node_position(
		root_instance,
		Vector2.ZERO,
		root_instance.size * Vector2(0.5, 1.0)
	)
	return [root_instance, root_key]

func _add_nodes_to_menu() -> void:
	for child: Control in node_buttons.get_children():
		if child.is_queued_for_deletion(): continue
		child.queue_free()

	var categories: Array = HTNGlobals.NODES.keys()
	categories.sort()
	for category: String in categories:
		if category == "Root": continue

		var tree_drop_button_instance: TreeDropButton = TREE_DROP_BUTTON.instantiate()
		node_buttons.add_child(tree_drop_button_instance)
		tree_drop_button_instance.set_title(category)

		var node_names: Array = HTNGlobals.NODES[category].keys()
		node_names.sort()
		for node_name: String in node_names:
			tree_drop_button_instance.add_menu_item(
				node_name,
				func() -> void:
					_add_node(HTNGlobals.NODES[category][node_name])
			)

func _show_all() -> void:
	for tree_drop_down: TreeDropButton in node_buttons.get_children():
		tree_drop_down.show_all()

func _hide_all() -> void:
	for tree_drop_down: TreeDropButton in node_buttons.get_children():
		tree_drop_down.hide()

func _add_node(node: PackedScene) -> HTNBaseNode:
	hide()
	var node_instance: HTNBaseNode = node.instantiate()
	_manager.current_graph.add_child(node_instance)
	_manager.current_graph.register_node(node_instance)

	if connect_node_data.is_empty():
		var node_size := (node_instance as HTNBaseNode).size
		_set_node_position(
			node_instance,
			_mouse_local_position,
			-(node_size / 2.0)
		)
	else:
		_place_and_connect(node_instance)

	node_instance.initialize(_manager)
	return node_instance

func _place_and_connect(node_instance: HTNBaseNode) -> void:
	_set_node_position(
		node_instance,
		connect_node_data["release_position"],
		-(node_instance.size / 2.0)
	)

	var from_node: StringName = connect_node_data["from_node"]
	var from_port: int = connect_node_data["from_port"]
	for idx in node_instance.get_input_port_count():
		var to_node := node_instance.name
		var to_port := node_instance.get_input_port_slot(idx)

		if _manager.current_graph.connection_handler.is_connection_valid(from_node, from_port, to_node, to_port):
			_manager.current_graph.connect_node(from_node, from_port, to_node, to_port)
			connect_node_data.clear()
			return
	connect_node_data.clear()

func _set_node_position(node: HTNBaseNode, target_position: Vector2, offset: Vector2) -> void:
	var scroll_offset := _manager.current_graph.scroll_offset
	var zoom := _manager.current_graph.zoom
	node.set_position_offset((target_position + scroll_offset) / zoom + offset)

func _on_visibility_changed() -> void:
	if not _manager: return

	if _manager.current_graph == null:
		hide()
		return

	if visible: _mouse_local_position = _manager.current_graph.get_local_mouse_position()
