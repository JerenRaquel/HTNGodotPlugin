@tool
class_name HTNTaskPanelManager
extends VBoxContainer

const TASK_LINE = preload("res://addons/HTNDomainManager/PluginSystem/TaskPanel/TaskLine/task_line.tscn")

@onready var task_name_line_edit: LineEdit = %TaskNameLineEdit
@onready var task_list: VBoxContainer = %TaskList
@onready var search_bar: LineEdit = %SearchBar

var _manager: HTNDomainManager
var _avoid_refresh := false

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	hide()
	_refresh_list()
	_manager.task_created.connect(_refresh_list)

func _refresh_list() -> void:
	if _avoid_refresh:
		_avoid_refresh = false
		return

	for child: HTNTaskLine in task_list.get_children():
		if child.is_queued_for_deletion(): continue
		child.queue_free()
	var data: Array = _manager.file_manager.get_all_task_names()
	if data.is_empty():
		search_bar.editable = false
		search_bar.placeholder_text = "Create a task..."
		return
	else:
		search_bar.editable = true
		search_bar.placeholder_text = "Search..."

	data.sort()
	for task_name: String in data:
		_create_task_line(task_name)

func _filter_children(filter: String) -> void:
	var filter_santized := filter.to_lower()
	for child: HTNTaskLine in task_list.get_children():
		var line_name: String = child.edit_button.text.to_lower()
		if filter_santized.is_empty() or line_name.contains(filter_santized):
			child.show()
		else:
			child.hide()

func _create_task_line(task_name: String) -> void:
	var task_line_instance := TASK_LINE.instantiate()
	task_list.add_child(task_line_instance)
	task_line_instance.initialize(_manager, task_name)

func _on_create_button_pressed() -> void:
	var task_name: String = task_name_line_edit.text
	if not _manager.file_manager.check_if_valid_name(task_name): return
	if not _manager.file_manager.create_task(task_name): return

	_create_task_line(task_name)
	_avoid_refresh = true
	_manager.task_created.emit()

func _on_search_bar_text_changed(new_text: String) -> void:
	_filter_children(new_text)
