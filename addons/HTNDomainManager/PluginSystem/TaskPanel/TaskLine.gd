@tool
extends HBoxContainer

@onready var task_name_button: Button = %TaskName

var _manager: HTNDomainManager
var _task_name: StringName
var _delete_callback: Callable

func initialize(manager: HTNDomainManager, task_name: StringName, delete_callback: Callable) -> void:
	_manager = manager
	_task_name = task_name.replace(" ", "")
	task_name_button.text = task_name
	_delete_callback = delete_callback

func contains(what: String) -> bool:
	var self_lower: String = _task_name.to_lower()
	var what_lower: String = what.to_lower()
	return self_lower.contains(what_lower)

func _on_warning_accept() -> void:
	_manager.serializer.delete_primitive_task(_task_name)
	_delete_callback.call(_task_name)

func _on_task_name_pressed() -> void:
	_manager.serializer.edit_script(_task_name)

func _on_delete_pressed() -> void:
	_manager.warning_screen.open(
		"You are about to delete " + _task_name + "\nAre you sure?",
		_on_warning_accept,
		Callable()
	)
