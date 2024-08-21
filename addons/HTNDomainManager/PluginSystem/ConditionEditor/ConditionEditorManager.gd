@tool
class_name HTNConditionEditor
extends Panel

const CONDITION_LINE: PackedScene\
	= preload("res://addons/HTNDomainManager/PluginSystem/ConditionEditor/condition_line/condition_line.tscn")

@onready var condition_line_container: VBoxContainer = %ConditionLineContainer
@onready var nickname_line_edit: LineEdit = %NicknameLineEdit
@onready var search_bar: LineEdit = %SearchBar

var _method_node: HTNMethodNode

func _ready() -> void:
	hide()

func open(node: HTNMethodNode, data: Array[Array]) -> void:
	show()
	_method_node = node
	nickname_line_edit.text = _method_node._nick_name
	search_bar.clear()
	_filter_children("")
	if data.is_empty(): return

	for condition: Array in data:
		_create_and_load_condition(condition)

func _filter_children(filter: String) -> void:
	var filter_santized := filter.to_lower()
	for child: HTNConditionLine in condition_line_container.get_children():
		var line_name: String = child.world_state_line_editor.text.to_lower()
		if filter_santized.is_empty() or line_name.contains(filter_santized):
			child.show()
		else:
			child.hide()

func _create_and_load_condition(data: Array=[]) -> void:
	var condition_line := CONDITION_LINE.instantiate()
	condition_line_container.add_child(condition_line)
	condition_line.initialize(data)

func _get_data() -> Array[Array]:
	var data: Array[Array] = []
	for child: HTNConditionLine in condition_line_container.get_children():
		var child_data: Array[Variant] = child.get_data()
		if child_data.is_empty(): continue	# Ignore invalid conditions

		data.push_back(child_data)
	return data

func _on_add_button_pressed() -> void:
	_create_and_load_condition()

func _on_close_button_pressed() -> void:
	hide()
	# Save Data
	_method_node._nick_name = nickname_line_edit.text
	var data: Array[Array] = _get_data()

	var different_data := false
	if data.size() != _method_node.condition_data.size():
		different_data = true
	else:
		for condition: Array in data:
			if condition not in _method_node.condition_data:
				different_data = true
				break
	_method_node.condition_data = data

	# Reset Editor
	for child: HTNConditionLine in condition_line_container.get_children():
		child.queue_free()

	if different_data:
		HTNGlobals.current_graph.is_saved = false

func _on_search_bar_text_changed(new_text: String) -> void:
	_filter_children(new_text)
