@tool
class_name HTNPrimitiveNode
extends HTNBaseNode

const NODE_FIELD = preload("res://addons/HTNDomainManager/PluginSystem/Components/NodeField/node_field.tscn")

@onready var waiting_button: CheckButton = %WaitingButton
@onready var menu_option_button: OptionButton = %MenuOptionButton
@onready var extension: VBoxContainer = %Extension

var _selected_task: String
var _requires_waiting: bool

func initialize(manager: HTNDomainManager) -> void:
	super(manager)

	_requires_waiting = waiting_button.button_pressed
	_update_task_list()
	_set_and_extend_default()
	_manager.task_panel.file_system_updated.connect(_on_file_system_update)

func get_node_name() -> String:
	if _selected_task.is_empty() or _selected_task == "": return ""
	return "Primitive - " + _selected_task

func validate_self() -> String:
	return ""

func load_data(data) -> void:
	_selected_task = data
	for idx: int in menu_option_button.item_count:
		if menu_option_button.get_item_text(idx) == data:
			menu_option_button.select(idx)
			#return
			break
	var export_data := _manager.serializer.get_script_export_data(_selected_task)
	_extend_node_parameters(export_data)

func get_task_name() -> String:
	if _selected_task.is_empty() or _selected_task == "": return ""
	return _selected_task

func write_data() -> bool:
	if _selected_task.is_empty() or _selected_task == "": return false

	var data: Array[Dictionary] = []
	data.push_back({
		"name": "requires_awaiting",
		"value": _requires_waiting
	})
	for child:HTNNodeField in extension.get_children():
		data.push_back(child.get_data())

	return _manager.serializer.set_script_export_data(_selected_task, data)

func _set_and_extend_default() -> void:
	if menu_option_button.item_count == 0:
		_selected_task = ""
		return

	if menu_option_button.get_item_text(0) != "":
		menu_option_button.select(0)
		_selected_task = menu_option_button.get_item_text(0)
		var export_data := _manager.serializer.get_script_export_data(_selected_task)
		_extend_node_parameters(export_data)
	else:
		_selected_task = ""

func _update_task_list() -> void:
	var options: Array = _manager.task_panel.get_all_primitive_task_names()
	menu_option_button.clear()
	if options.size() == 0: return

	var idx := 0
	for option in options:
		menu_option_button.add_item(option, idx)
		idx += 1

func _extend_node_parameters(export_data: Dictionary) -> void:
	for child in extension.get_children(): child.queue_free()
	if export_data.is_empty(): return

	for key: String in export_data.keys():
		if key == "requires_awaiting":
			waiting_button.button_pressed = export_data[key]["value"]
			continue

		var node_field_instance: HTNNodeField = NODE_FIELD.instantiate()
		extension.add_child(node_field_instance)
		node_field_instance.set_data(key, export_data[key])

func _on_file_system_update() -> void:
	_update_task_list()
	if _selected_task.is_empty() or _selected_task == "": return

	for idx: int in menu_option_button.item_count:
		if menu_option_button.get_item_text(idx) == _selected_task:
			menu_option_button.select(idx)
			return
	_set_and_extend_default()

func _on_menu_option_button_item_selected(index: int) -> void:
	_selected_task = menu_option_button.get_item_text(index)
	var export_data := _manager.serializer.get_script_export_data(_selected_task)
	_extend_node_parameters(export_data)

func _on_edit_file_pressed() -> void:
	_manager.serializer.edit_script(_selected_task)

func _on_waiting_button_toggled(toggled_on: bool) -> void:
	_requires_waiting = toggled_on
