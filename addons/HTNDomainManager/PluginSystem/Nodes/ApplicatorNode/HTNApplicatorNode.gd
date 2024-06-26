@tool
class_name HTNApplicatorNode
extends HTNBaseNode

@onready var edit_button: Button = $EditButton

var _nick_name: String:
	set(value):
		_nick_name = value
		HTNGlobals.node_name_altered.emit()
		if value.is_empty():
			title = "Applicator"
		else:
			title = "Applicator - " + value

var effect_data: Dictionary

func get_node_name() -> String:
	if not _nick_name.is_empty():
		return _nick_name
	return ""

func get_node_type() -> String:
	return "Applicator"

func validate_self() -> String:
	if effect_data.is_empty():
		return "There are no effects set."
	else:
		for world_state: StringName in effect_data.keys():
			if not world_state.is_empty(): continue
			return "Missing WorldStateKey field for efftect"
		return ""

func load_data(data) -> void:
	_nick_name = data["nickname"]
	effect_data = data["effect_data"]

func get_data() -> Dictionary:
	return {
		"effect_data": effect_data,
		"nickname": _nick_name
	}

func _on_edit_button_pressed() -> void:
	HTNGlobals.effect_editor.open(self, effect_data)
