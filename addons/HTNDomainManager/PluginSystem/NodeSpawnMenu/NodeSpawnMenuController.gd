@tool
class_name HTNNodeSpawnMenu
extends Control

## Node Data
#Color Code:
#- Compound/Root <-> Methods: 4f8fba
#- Tasks <-> Tasks: 468232
#
#IDs:
#- Compound/Root <-> Methods: 1
#- Tasks <-> Tasks: 2

const HTN_ROOT_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/RootNode/htn_root_node.tscn")
const HTN_COMMENT_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/CommentNode/htn_comment_node.tscn")
const HTN_SPLITTER_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/SplitterNode/htn_splitter_node.tscn")
const HTN_METHOD_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/MethodNode/Original/htn_method_node.tscn")
const HTN_ALWAYS_TRUE_METHOD_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/MethodNode/AlwaysTrue/htn_always_true_method_node.tscn")
const HTN_APPLICATOR_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/ApplicatorNode/htn_applicator_node.tscn")
const HTN_TASK_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/TaskNode/htn_task_node.tscn")
const HTN_DOMAIN_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/DomainNode/htn_domain_node.tscn")

@onready var splitter: Button = %Splitter
@onready var domain_link: Button = %DomainLink
@onready var method: Button = %Method
@onready var at_method: Button = %ATMethod
@onready var task: Button = %Task
@onready var applicator: Button = %Applicator
@onready var comment: Button = %Comment

var _manager: HTNDomainManager
var _mouse_local_position: Vector2
var can_be_opened := false
var connect_node_data: Dictionary = {}

func _ready() -> void:
	if not Engine.is_editor_hint():
		set_process_unhandled_input(false)

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
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
			_hide_all()
			method.show()
			at_method.show()
		2:
			_hide_all()
			splitter.show()
			task.show()
			applicator.show()
			domain_link.show()
		_:
			_hide_all()
	show()
	global_position = get_global_mouse_position()

func spawn_root() -> Array:
	assert(_manager.current_graph != null, "Current Graph is NULL")

	var root_instance: HTNRootNode = HTN_ROOT_NODE.instantiate()
	_manager.current_graph.add_child(root_instance)
	root_instance.initialize(_manager)
	var root_key: String = _manager.current_graph.register_node(root_instance)
	_set_node_position(
		root_instance,
		Vector2.ZERO,
		root_instance.size * Vector2(0.5, 1.0)
	)
	return [root_instance, root_key]

func _show_all() -> void:
	splitter.show()
	domain_link.show()
	method.show()
	at_method.show()
	task.show()
	applicator.show()
	comment.show()

func _hide_all() -> void:
	splitter.hide()
	domain_link.hide()
	method.hide()
	at_method.hide()
	task.hide()
	applicator.hide()
	comment.hide()

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

func _on_splitter_pressed() -> void:
	_add_node(HTN_SPLITTER_NODE).initialize(_manager)

func _on_domain_link_pressed() -> void:
	_add_node(HTN_DOMAIN_NODE).initialize(_manager)

func _on_method_pressed() -> void:
	_add_node(HTN_METHOD_NODE).initialize(_manager)

func _on_at_method_pressed() -> void:
	_add_node(HTN_ALWAYS_TRUE_METHOD_NODE).initialize(_manager)

func _on_task_pressed() -> void:
	_add_node(HTN_TASK_NODE).initialize(_manager)

func _on_applicator_pressed() -> void:
	_add_node(HTN_APPLICATOR_NODE).initialize(_manager)

func _on_comment_pressed() -> void:
	_add_node(HTN_COMMENT_NODE).initialize(_manager)

func _on_visibility_changed() -> void:
	if _manager == null or _manager.current_graph == null:
		hide()
		return

	if visible: _mouse_local_position = _manager.current_graph.get_local_mouse_position()
