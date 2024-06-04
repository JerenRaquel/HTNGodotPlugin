@tool
class_name HTNSplitterNode
extends HTNBaseNode

@onready var nick_name: LineEdit = $NickName

var _nick_name: String

func initialize(manager: HTNDomainManager) -> void:
	super(manager)

func get_node_name() -> String:
	return _nick_name

func validate_self() -> String:
	return ""

func load_data(data) -> void:
	var parsed_nickname := (data as String)
	nick_name.text = parsed_nickname
	_nick_name = parsed_nickname

func _on_nick_name_text_changed(new_text: String) -> void:
	_nick_name = new_text
