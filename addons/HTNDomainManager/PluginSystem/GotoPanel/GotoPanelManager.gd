@tool
class_name HTNGoToManager
extends VBoxContainer

@onready var goto_root_button: Button = %GotoRootButton
@onready var search_bar: LineEdit = %SearchBar
@onready var goto_container: VBoxContainer = %GotoContainer

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	_manager.graph_altered.connect(_refresh)
	_manager.node_name_altered.connect(_refresh)
	hide()

func _refresh() -> void:
	if not visible: return

	search_bar.clear()
	goto_root_button.disabled = (_manager.current_graph == null)

	if not _manager.current_graph:
		search_bar.editable = false
		return

	for child: Button in goto_container.get_children():
		if child.is_queued_for_deletion(): continue
		child.queue_free()

	var node_naming_data: Dictionary = _manager.current_graph.get_node_keys_with_meta()
	var node_keys: Array[StringName] = []
	for node_key: StringName in node_naming_data.keys():
		if node_key == _manager.current_graph.root_key: continue
		node_keys.push_back(node_key)

	if node_keys.is_empty():
		search_bar.editable = false
		return

	# Sort based on type, then sandwich ID
	node_keys.sort_custom(
		func(node_key_A: StringName, node_key_B: StringName) -> bool:
			if node_naming_data[node_key_A]["type"] < node_naming_data[node_key_B]["type"]:
				return true
			else:
				return int(node_key_A.replace("Sandwich_", "")) < int(node_key_B.replace("Sandwich_", ""))
	)

	for node_key: StringName in node_keys:
		var node_name: String = node_naming_data[node_key]["name"]
		var node_type: String = node_naming_data[node_key]["type"]
		# TODO: List the nodetype_keyID
		if node_name.is_empty():
			node_name = node_type + " - " + node_key.replace("Sandwich_", "Sandwich_ID_")
		else:
			node_name = node_type + " - " + node_name

		var button_instance := Button.new()
		button_instance.text = node_name
		button_instance.pressed.connect( func() -> void: _center_on_node(node_key) )
		goto_container.add_child(button_instance)

	search_bar.editable = true

func _center_on_node(node_key: StringName) -> void:
	var data: Dictionary = _manager.current_graph.get_node_offset_by_key(node_key)
	if data.is_empty(): return

	_manager.current_graph.zoom = 1.0
	var center := _manager.current_graph.size / 2
	var offset: Vector2 = data["offset"] + data["size"] * Vector2(0.5, 1.0) - center
	_manager.current_graph.scroll_offset = offset / _manager.current_graph.zoom

func _on_visibility_changed() -> void:
	if not _manager: return

	if visible:
		search_bar.clear()
		_refresh()
	else:
		search_bar.clear()

func _on_goto_root_button_pressed() -> void:
	_center_on_node(_manager.current_graph.root_key)

func _on_search_bar_text_changed(new_text: String) -> void:
	var filter_santized := new_text.to_lower()
	for child: Button in goto_container.get_children():
		var line_name: String = child.text.to_lower()
		if filter_santized.is_empty() or line_name.contains(filter_santized):
			child.show()
		else:
			child.hide()
