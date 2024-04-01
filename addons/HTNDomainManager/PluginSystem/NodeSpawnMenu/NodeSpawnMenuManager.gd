@tool
class_name NodeSpawnMenu
extends Control

## Node Data
#Color Code:
#- Compound/Root <-> Methods: 4f8fba
#- Tasks <-> Tasks: 468232
#
#IDs:
#- Compound/Root <-> Methods: 1
#- Tasks <-> Tasks: 2

const COMPOUND_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/CompoundNode/compound_node.tscn")
const METHOD_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/MethodNode/Original/method_node.tscn")
const ALWAYS_TRUE_METHOD = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/MethodNode/AlwaysTrue/always_true_method.tscn")
const PRIMITIVE_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/PrimitiveNode/primitive_node.tscn")
const ROOT_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/RootNode/root_node.tscn")
const APPLICATOR_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/ApplicatorNode/applicator_node.tscn")
const COMMENT_NODE = preload("res://addons/HTNDomainManager/PluginSystem/Nodes/CommentNode/comment_node.tscn")

@onready var compound: Button = %Compound
@onready var method: Button = %Method
@onready var always_method: Button = %AlwaysMethod
@onready var primitive: Button = %Primitive
@onready var applicator: Button = %Applicator
@onready var comment: Button = %Comment

var _manager: HTNDomainManager
var _mouse_local_position: Vector2

var connect_node_data: Dictionary = {}

func initialize(manager: HTNDomainManager) -> void:
	hide()
	_manager = manager

func spawn_root() -> GraphNode:
	var root_instance: GraphNode = ROOT_NODE.instantiate()
	_manager.graph_handler.graph_edit.add_child(root_instance)
	_manager.graph_handler.register_node(root_instance)
	_set_node_position(
		root_instance,
		Vector2.ZERO,
		root_instance.size * Vector2(0.5, 1.0)
	)
	return root_instance

func enable_usable_nodes(port_type: int) -> void:
	match port_type:
		-1, 0:
			_show_all()
		1:
			_hide_all()
			method.show()
			always_method.show()
		2:
			_hide_all()
			compound.show()
			primitive.show()
			applicator.show()
		_:
			_hide_all()

func _show_all() -> void:
	compound.show()
	method.show()
	primitive.show()
	always_method.show()
	applicator.show()
	comment.show()

func _hide_all() -> void:
	compound.hide()
	method.hide()
	always_method.hide()
	primitive.hide()
	applicator.hide()
	comment.hide()

func _add_node(node: PackedScene) -> GraphNode:
	hide()
	var node_instance: GraphNode = node.instantiate()
	_manager.graph_handler.graph_edit.add_child(node_instance)
	_manager.graph_handler.register_node(node_instance)

	if connect_node_data.is_empty():
		var node_size := (node_instance as GraphNode).size
		_set_node_position(
			node_instance,
			_mouse_local_position,
			-(node_size / 2.0)
		)
	else:
		_place_and_connect(node_instance)

	node_instance.node_selected.connect(func(): _manager.graph_handler.register_selected.call(node_instance))
	node_instance.node_deselected.connect(func(): _manager.graph_handler.unregister_selected.call(node_instance))
	return node_instance

func _place_and_connect(node_instance: GraphNode) -> void:
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

		if _manager.graph_handler.is_connection_valid(from_node, from_port, to_node, to_port):
			_manager.graph_handler.graph_edit.connect_node(from_node, from_port, to_node, to_port)
			connect_node_data.clear()
			return
	connect_node_data.clear()

func _set_node_position(node: GraphNode, target_position: Vector2, offset: Vector2) -> void:
	var scroll_offset := _manager.graph_handler.graph_edit.scroll_offset
	var zoom := _manager.graph_handler.graph_edit.zoom
	node.set_position_offset((target_position + scroll_offset) / zoom + offset)

func _on_compound_pressed() -> void:
	_add_node(COMPOUND_NODE).initialize(_manager)

func _on_method_pressed() -> void:
	_add_node(METHOD_NODE).initialize(_manager)

func _on_always_method_pressed() -> void:
	_add_node(ALWAYS_TRUE_METHOD).initialize(_manager)

func _on_primitive_pressed() -> void:
	_add_node(PRIMITIVE_NODE).initialize(_manager)

func _on_applicator_pressed() -> void:
	_add_node(APPLICATOR_NODE).initialize(_manager)

func _on_comment_pressed() -> void:
	_add_node(COMMENT_NODE).initialize(_manager)

func _on_visibility_changed() -> void:
	if _manager == null: return

	if visible:
		_mouse_local_position = _manager.graph_handler.graph_edit.get_local_mouse_position()
