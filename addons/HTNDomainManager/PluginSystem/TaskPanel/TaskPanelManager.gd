@tool
class_name HTNTaskPanelManager
extends VBoxContainer

const TASK_LINE = preload("res://addons/HTNDomainManager/PluginSystem/TaskPanel/TaskLine/task_line.tscn")

signal task_created

@onready var task_name_line_edit: LineEdit = %TaskNameLineEdit
@onready var task_list: VBoxContainer = %TaskList

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	hide()
	_refresh_list()
	task_created.connect(_refresh_list)

func _refresh_list() -> void:
	for child: HTNTaskLine in task_list.get_children():
		if child.is_queued_for_deletion(): continue
		child.queue_free()
	var data: Array = _manager.file_manager.get_all_task_names()
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

#func _sort_list() -> void:
	#_primitives.sort()
	#var child_count := _task_list.get_child_count()
	#while _primitives.size() < child_count:
		#var child := _task_list.get_child(0)
		#child.queue_free()
		#child_count -= 1
	#await get_tree().process_frame
#
	#var idx := 0
	#for task_line: HBoxContainer in _task_list.get_children():
		#if task_line.is_queued_for_deletion(): continue
#
		#task_line.initialize(
			#_manager,
			#_manager.serializer.prettify_task_name(_primitives[idx]),
			#func(file_name: String):
				#var file := file_name + ".tres"
				#if file in _primitives:
					#_primitives.erase(file)
				#_on_refresh_pressed()
				#file_system_updated.emit()
		#)
		#idx += 1
#
#func _on_file_deleted(file_path: String) -> void:
	## Dont fire on scripts, only the resources
	## At least for now
	#if file_path.ends_with(".gd"): return
#
	## On fail, the file wasn't recorded
	#if not _remove_file_from_task_list(file_path): return
#
	#_on_refresh_pressed()
	#file_system_updated.emit()

func _on_create_button_pressed() -> void:
	var task_name: String = task_name_line_edit.text
	if not _manager.file_manager.check_if_valid_name(task_name): return
	if not _manager.file_manager.create_task(task_name): return

	_create_task_line(task_name)

func _on_search_bar_text_changed(new_text: String) -> void:
	_filter_children(new_text)
