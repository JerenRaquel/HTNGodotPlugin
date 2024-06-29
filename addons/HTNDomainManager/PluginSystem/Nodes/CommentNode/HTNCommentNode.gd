@tool
class_name HTNCommentNode
extends HTNBaseNode

@onready var text_edit: TextEdit = $TextEdit

func get_node_name() -> String:
	return ""

func validate_self() -> String:
	return ""

func load_data(data: Dictionary) -> void:
	text_edit.text = data["comment_text"]
