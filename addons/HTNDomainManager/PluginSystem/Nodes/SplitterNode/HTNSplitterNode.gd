@tool
class_name HTNSplitterNode
extends HTNBaseNode

@onready var nick_name: LineEdit = $NickName

func get_node_name() -> String:
	return nick_name.text

func validate_self() -> String:
	return ""

func load_data(data: Dictionary) -> void:
	nick_name.text = data["nickname"]

func _on_nick_name_text_submitted(new_text: String) -> void:
	_manager.node_name_altered.emit()
