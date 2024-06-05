@tool
class_name HTNTaskPanelManager
extends VBoxContainer

signal task_created

@onready var task_name_line_edit: LineEdit = %TaskNameLineEdit
@onready var task_list: VBoxContainer = %TaskList

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	_refresh_list()
	task_created.connect(_refresh_list)

func get_all_task_file_names() -> Array[String]:
	var data: Array[String] = []

	return data

func _refresh_list() -> void:
	pass

#const TASK_LINE = preload("res://addons/HTNDomainManager/PluginSystem/TaskPanel/task_line.tscn")
#
#var _primitives: Array[String]
#
#func get_all_primitive_task_names() -> Array:
	#return _primitives.map(
		#func(file_name: String):
			#return _manager.serializer.prettify_task_name(file_name).replace(" ", "")
	#)
#
#func _remove_file_from_task_list(file_path: String) -> bool:
	#var tokens := file_path.split("/", false)
	#var file_name := tokens[-1]
#
	#if file_name in _primitives:
		#_primitives.erase(file_name)
		#return true
	#return false
#
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
#func _update_visible_task_list(filter: String) -> void:
	#for task_line: HBoxContainer in _task_list.get_children():
		#if filter.is_empty() or task_line.contains(filter):
			#task_line.show()
		#else:
			#task_line.hide()
#
#func _refresh_tasks_from(path: String, list: Array[String]) -> void:
	#var file_names := DirAccess.get_files_at(path)
	#for file_name in file_names:
		#if file_name not in list:
			#var task_line := TASK_LINE.instantiate()
			#_task_list.add_child(task_line)
			#list.push_back(file_name)
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
	pass # Replace with function body.
