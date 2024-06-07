@tool
class_name HTNMethodNode
extends HTNBaseNode

const PREFIX := "Method - "

var _priority: int = 0
var _nick_name: String:
	set(value):
		_nick_name = value
		_manager.node_name_altered.emit()
		if value == "":
			title = "Method"
		else:
			title = PREFIX + value

var condition_data: Dictionary = {}

func initialize(manager: HTNDomainManager) -> void:
	super(manager)

func get_node_name() -> String:
	if not _nick_name.is_empty():
		return _nick_name
	return ""

func validate_self() -> String:
	if condition_data.is_empty():
		return "There are no conditions set."
	else:
		for world_state_key: String in condition_data:
			if world_state_key != "": continue
			return "Missing WorldStateKey field for at least one condition."
		return ""

func load_data(data: Dictionary) -> void:
	_nick_name = data["nickname"]
	condition_data = data["condition_data"]
	_priority = data["priority"]
	%SpinBox.value = _priority

func get_priority() -> int:
	return _priority

func _on_conditions_pressed() -> void:
	_manager.condition_editor.open(self, condition_data)

func _on_spin_box_value_changed(value: float) -> void:
	_priority = int(value)
