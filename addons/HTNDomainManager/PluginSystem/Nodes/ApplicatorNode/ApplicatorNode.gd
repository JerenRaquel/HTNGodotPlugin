@tool
class_name HTNApplicatorNode
extends HTNBaseNode

@onready var edit_effects: Button = $EditEffects

var _nick_name: String:
	set(value):
		_nick_name = value
		if value == "":
			title = "Applicator"
		else:
			title = "Applicator - " + value

var effect_data: Dictionary

func initialize(manager: HTNDomainManager) -> void:
	super(manager)

func get_node_name() -> String:
	if _nick_name != "" and not _nick_name.is_empty():
		return title
	return ""

func validate_self() -> String:
	if effect_data.is_empty():
		return "There are no effects set."
	else:
		for wprld_state_key: String in effect_data:
			if wprld_state_key != "": continue
			return "Missing WorldStateKey field for efftect"
		return ""

func load_data(data) -> void:
	title = data["nick_name"]
	_nick_name = title.replace("Applicator - ", "")
	effect_data = data["data"]

func _on_edit_effects_pressed() -> void:
	_manager.effect_editor.open(self, effect_data)
