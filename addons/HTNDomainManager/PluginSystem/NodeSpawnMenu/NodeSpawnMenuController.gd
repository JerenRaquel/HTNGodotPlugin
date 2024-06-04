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

@onready var splitter: Button = %Splitter
@onready var domain_link: Button = %DomainLink
@onready var method: Button = %Method
@onready var at_method: Button = %ATMethod
@onready var task: Button = %Task
@onready var applicator: Button = %Applicator
@onready var comment: Button = %Comment

var _manager: HTNDomainManager
var _mouse_local_position: Vector2

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	hide()

func spawn_root() -> GraphNode:
	assert(_manager.current_graph != null, "Current Graph is NULL")

	var root_instance: GraphNode = HTN_ROOT_NODE.instantiate()
	_manager.current_graph.add_child(root_instance)
	_manager.current_graph.register_node(root_instance)
	_set_node_position(
		root_instance,
		Vector2.ZERO,
		root_instance.size * Vector2(0.5, 1.0)
	)
	return root_instance

func enable(port_type: int) -> void:
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
		_:
			_hide_all()
	show()

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

func _add_node() -> void:
	pass

func _set_node_position(node: GraphNode, target_position: Vector2, offset: Vector2) -> void:
	var scroll_offset := _manager.current_graph.scroll_offset
	var zoom := _manager.current_graph.zoom
	node.set_position_offset((target_position + scroll_offset) / zoom + offset)

func _on_splitter_pressed() -> void:
	pass # Replace with function body.

func _on_domain_link_pressed() -> void:
	pass # Replace with function body.

func _on_method_pressed() -> void:
	pass # Replace with function body.

func _on_at_method_pressed() -> void:
	pass # Replace with function body.

func _on_task_pressed() -> void:
	pass # Replace with function body.

func _on_applicator_pressed() -> void:
	pass # Replace with function body.

func _on_comment_pressed() -> void:
	pass # Replace with function body.

func _on_visibility_changed() -> void:
	if _manager == null or _manager.current_graph == null:
		hide()
		return

	if visible: _mouse_local_position = _manager.current_graph.get_local_mouse_position()
