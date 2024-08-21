@tool
class_name HTNMethodNode
extends HTNBaseNode

const PREFIX := "Method - "

var _priority: int = 0
var _nick_name: String:
	set(value):
		_nick_name = value
		HTNGlobals.node_name_altered.emit()
		if value == "":
			title = "Method"
		else:
			title = PREFIX + value

var condition_data: Array[Array] = []:
	set(value):
		condition_data = value
		_update_tool_tip()

func get_node_name() -> String:
	if not _nick_name.is_empty():
		return _nick_name
	return ""

func get_node_type() -> String:
	return "Method"

func validate_self() -> String:
	if condition_data.is_empty():
		return "There are no conditions set."
	return ""

func load_data(data: Dictionary) -> void:
	_nick_name = data["nickname"]
	condition_data = data["condition_data"]
	_priority = data["priority"]
	%SpinBox.value = _priority

func get_data() -> Dictionary:
	return {
		"condition_data": condition_data,
		"nickname": _nick_name,
		"priority": get_priority()
	}

func get_priority() -> int:
	return _priority

func _update_tool_tip() -> void:
	if condition_data.is_empty():
		tooltip_text = ""
		return

	if condition_data.size() == 1:
		if condition_data[0][0] == "AlwaysTrue":
			tooltip_text = ""
			return

	var text: String = ""
	for condition: Array in condition_data:
		text += _data_to_str(condition)
		text += "\n"

	tooltip_text = text

func _data_to_str(condition: Array) -> String:
	var text: String = ""
	var idx: int = 0
	for token: Variant in condition:
		if token is String and token.begins_with("$"):
			text += "WorldState['" + token.replace("$", "") + "']"
		else:
			text += str(token)

		if idx < condition.size()-1:
			text += " "

	return text

func _on_conditions_pressed() -> void:
	HTNGlobals.condition_editor.open(self, condition_data)

func _on_spin_box_value_changed(value: float) -> void:
	_priority = int(value)
	HTNGlobals.current_graph.is_saved = false
