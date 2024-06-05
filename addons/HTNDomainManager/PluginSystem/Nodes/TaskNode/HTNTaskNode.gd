@tool
class_name HTNTaskNode
extends HTNBaseNode

@onready var task_option_button: OptionButton = %TaskOptionButton

func initialize(manager: HTNDomainManager) -> void:
	super(manager)

func get_node_name() -> String:
	return task_option_button.get_item_text(task_option_button.selected)

func validate_self() -> String:
	return ""

func load_data(data) -> void:
	pass

func _on_edit_button_pressed() -> void:
	_manager.file_manager.edit_script(get_node_name())
