@tool
class_name HTNEffectEditor
extends Panel

const EFFECT_LINE = preload("res://addons/HTNDomainManager/PluginSystem/EffectEditor/effect_line.tscn")

@onready var nick_name_line_edit: LineEdit = %NickNameLineEdit
@onready var line_parent: VBoxContainer = $VBoxContainer/LineParent
@onready var search_bar: LineEdit = %SearchBar

var _manager: HTNDomainManager
var _applicator_node: HTNApplicatorNode
var _effects: Array[StringName]

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	hide()

func open(applicator_node: HTNApplicatorNode, data: Dictionary) -> void:
	_applicator_node = applicator_node
	_effects.clear()
	show()
	# Load data
	nick_name_line_edit.text = applicator_node._nick_name
	for world_state_key: StringName in data:
		if world_state_key in _effects: continue

		var effect_line_instance := EFFECT_LINE.instantiate()
		line_parent.add_child(effect_line_instance)
		effect_line_instance.initialize(world_state_key, data[world_state_key])
		_effects.push_back(world_state_key)
	search_bar.clear()
	_filter_lines("")

func _filter_lines(filter: String) -> void:
	for child: HBoxContainer in line_parent.get_children():
		if filter == "" or child._world_state_key.contains(filter):
			child.show()
		else:
			child.hide()

func _on_close_pressed() -> void:
	hide()
	# Save data
	var data: Dictionary = {}
	for child in line_parent.get_children():
		if child.is_queued_for_deletion(): continue

		var child_data: Dictionary = child.get_data()
		if child_data["key"] == "" or child_data["key"].is_empty(): continue

		data[child_data["key"]] = {
			"type_id": child_data["type_id"],
			"value": child_data["value"]
		}
	_applicator_node.effect_data = data
	_applicator_node._nick_name = nick_name_line_edit.text
	for child in line_parent.get_children():
		if child.is_queued_for_deletion(): continue
		child.queue_free()

func _on_add_effect_pressed() -> void:
	var effect_line_instance := EFFECT_LINE.instantiate()
	line_parent.add_child(effect_line_instance)
	effect_line_instance.initialize()

func _on_search_bar_text_changed(new_text: String) -> void:
	_filter_lines(new_text)
