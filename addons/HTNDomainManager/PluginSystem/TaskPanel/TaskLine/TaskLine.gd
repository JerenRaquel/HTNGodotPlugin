@tool
class_name HTNTaskLine
extends HBoxContainer

@onready var edit_button: Button = %EditButton

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager, task_name: String) -> void:
	_manager = manager
	edit_button.text = task_name

func _on_delete_button_pressed() -> void:
	if _manager.file_manager.delete_task(edit_button.text):
		_manager.warning_box.open(
			"You are about to delete this task for this graph and every graph that uses this.\nContinue?",
			func() -> void:
				_manager.task_deleted.emit()
				queue_free(),
			Callable()
		)
	else:
		_manager.notification_handler.send_error("Couldn't delete task: '" + edit_button.text + "'. Aborting...")

func _on_edit_button_pressed() -> void:
	_manager.file_manager.edit_script(edit_button.text)
