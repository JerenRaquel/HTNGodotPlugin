@tool
class_name HTNTaskNode
extends HTNBaseNode

const EMPTY_TASK_NAME := "N/A"

@onready var task_option_button: OptionButton = %TaskOptionButton
@onready var requires_waiting_button: CheckButton = %RequiresWaitingButton

func _exit_tree() -> void:
	_manager.task_deleted.disconnect(_refresh_list)
	_manager.task_created.disconnect(_refresh_list)

func initialize(manager: HTNDomainManager) -> void:
	super(manager)
	_refresh_list()
	_on_task_option_button_item_selected(0)
	manager.task_deleted.connect(_refresh_list)
	manager.task_created.connect(_refresh_list)

func get_node_name() -> String:
	return task_option_button.get_item_text(task_option_button.selected)

func get_node_type() -> String:
	return "Task"

func validate_self() -> String:
	return ""

func load_data(data: Dictionary) -> void:
	for idx: int in task_option_button.item_count:
		if task_option_button.get_item_text(idx) == data["task"]:
			task_option_button.select(idx)
			_on_task_option_button_item_selected(idx)
			return

func _refresh_list() -> void:
	var task_names: Array = _manager.file_manager.get_all_task_names()
	if task_names.size() == 0:
		task_option_button.clear()
		task_option_button.add_item(EMPTY_TASK_NAME)
		return

	task_names.sort()

	# Parse the currently selected task name
	var last_item: String
	if task_option_button.item_count == 1:
		last_item = task_option_button.get_item_text(0)
		if last_item == EMPTY_TASK_NAME:
			last_item = ""
	elif task_option_button.item_count > 1:
		last_item = task_option_button.get_item_text(task_option_button.selected)

	task_option_button.clear()

	# Add all the task names
	var idx := 0
	for task_name: String in task_names:
		task_option_button.add_item(task_name)
		if not last_item.is_empty() and task_name == last_item:
			task_option_button.select(idx)
			_on_task_option_button_item_selected(idx)
		idx += 1
	if last_item.is_empty():
		task_option_button.select(0)
		_on_task_option_button_item_selected(0)

func _on_edit_button_pressed() -> void:
	var task_name := get_node_name()
	if task_name == EMPTY_TASK_NAME: return
	_manager.file_manager.edit_script(task_name)

func _on_requires_waiting_button_toggled(toggled_on: bool) -> void:
	var task_name := get_node_name()
	if task_name == EMPTY_TASK_NAME: return
	_manager.file_manager.toggle_awaiting_task_state(task_name, toggled_on)

func _on_task_option_button_item_selected(index: int) -> void:
	requires_waiting_button\
		.set_pressed_no_signal(_manager.file_manager.get_awaiting_task_state(get_node_name()))
	_manager.node_name_altered.emit()
	HTNGlobals.graph_altered.emit()
