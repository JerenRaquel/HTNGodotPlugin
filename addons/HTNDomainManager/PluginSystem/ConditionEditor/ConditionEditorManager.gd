@tool
class_name HTNConditionEditor
extends Panel

const CONDITION_LINE = preload("res://addons/HTNDomainManager/PluginSystem/ConditionEditor/ConditionLine/condition_line.tscn")

@onready var condition_line_container: VBoxContainer = %ConditionLineContainer
@onready var nickname_line_edit: LineEdit = %NicknameLineEdit
@onready var search_bar: LineEdit = %SearchBar

var _manager: HTNDomainManager
var _method_node: HTNMethodNode
var _node_nick_name := ""

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	hide()

func open(node: HTNMethodNode, data: Dictionary) -> void:
	show()
	_method_node = node
	nickname_line_edit.text = _method_node._nick_name
	_node_nick_name = _method_node._nick_name

	# CRITICAL: Load data
	#if data.is_empty(): return
	#for key: StringName in data.keys():
		#_create_and_load_condition({
			#"key": key,
			#"compare_id": data[key]["compare_id"],
			#"type_id": data[key]["type_id"],
			#"value": data[key]["value"]
		#})
	search_bar.clear()
	_filter_children("")

func _filter_children(filter: String) -> void:
	for child: HBoxContainer in condition_line_container.get_children():
		if filter == "" or child._world_state_key.contains(filter):
			child.show()
		else:
			child.hide()

func _create_and_load_condition(data: Dictionary={}) -> void:
	var condition_line := CONDITION_LINE.instantiate()
	condition_line_container.add_child(condition_line)
	condition_line.initialize(data)

func _on_add_button_pressed() -> void:
	_create_and_load_condition()

#var _data: Dictionary = {}
#
#func _get_data() -> Dictionary:
	#var data := {}
#
	#for child: HBoxContainer in condition_parent.get_children():
		#var child_data: Dictionary = child.get_data()
		#if child_data["key"] in data: continue	# Skip Repeats
#
		#data[child_data["key"]] = {
			#"compare_id": child_data["compare_id"],
			#"type_id": child_data["type_id"],
			#"value": child_data["value"]
		#}
#
	#return data

#func _on_method_nick_name_text_changed(new_text: String) -> void:
	#_node_nick_name = new_text
#
#func _on_close_pressed() -> void:
	#hide()
	## Save Data
	#_method_node._nick_name = _node_nick_name
	#_method_node.condition_data = _get_data()
#
	## Reset Editor
	#for child: HBoxContainer in condition_parent.get_children():
		#child.free()
#
#func _on_search_bar_text_changed(new_text: String) -> void:
	#_filter_children(new_text)


