@tool
class_name HTNTaskNode
extends HTNBaseNode

@onready var task_option_button: OptionButton = %TaskOptionButton

func _exit_tree() -> void:
	_manager.task_deleted.disconnect(_refresh_list)
	_manager.task_created.disconnect(_refresh_list)

func initialize(manager: HTNDomainManager) -> void:
	super(manager)
	_refresh_list()
	manager.task_deleted.connect(_refresh_list)
	manager.task_created.connect(_refresh_list)

func get_node_name() -> String:
	return task_option_button.get_item_text(task_option_button.selected)

func validate_self() -> String:
	return ""

func load_data(data) -> void:
	pass

func _refresh_list() -> void:
	var task_names: Array = _manager.file_manager.get_all_task_names()
	task_names.sort()
	var last_item: String = task_option_button.get_item_text(task_option_button.selected)
	task_option_button.clear()
	var idx := 0
	for task_name: String in task_names:
		task_option_button.add_item(task_name)
		if task_name == last_item:
			task_option_button.select(idx)
		idx += 1

func _on_edit_button_pressed() -> void:
	_manager.file_manager.edit_script(get_node_name())
