@tool
class_name HTNGotoManager
extends VBoxContainer

var _manager: HTNDomainManager
var _parent: VBoxContainer
var _root_key: StringName

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	_parent = %Parent
	_root_key = _manager.graph_handler.get_root_key()
	_manager.graph_handler.graph_altered.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child: Button in _parent.get_children():
		child.free()

	var keys := _manager.graph_handler.nodes.keys()
	keys.sort()

	for node_key: StringName in keys:
		if node_key == _root_key: continue

		var button_instance := Button.new()
		button_instance.name = node_key
		button_instance.text = _manager.graph_handler.get_node_nickname(node_key)
		button_instance.pressed.connect( func() -> void: _center_on_node(node_key) )
		_parent.add_child(button_instance)

func _center_on_node(node_key: StringName) -> void:
	var data: Dictionary = _manager.graph_handler.get_node_offset_by_key(node_key)
	_manager.graph_handler.graph_edit.zoom = 1.0
	var center := _manager.graph_handler.graph_edit.size / 2
	var offset: Vector2 = data["offset"] + data["size"] * Vector2(0.5, 1.0) - center
	_manager.graph_handler.graph_edit.scroll_offset = offset / _manager.graph_handler.graph_edit.zoom

func _filter_list(filter: String) -> void:
	var search_key := filter.to_lower()
	for node_button: Button in _parent.get_children():
		var node_key: String = node_button.text.to_lower()
		if filter == "" or node_key.contains(search_key):
			node_button.show()
		else:
			node_button.hide()

func _on_goto_root_pressed() -> void:
	_center_on_node(_root_key)

func _on_refresh_button_pressed() -> void:
	_refresh()

func _on_search_bar_text_changed(new_text: String) -> void:
	_filter_list(new_text)
