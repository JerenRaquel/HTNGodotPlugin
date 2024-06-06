@tool
class_name HTNRootNode
extends HTNBaseNode

func initialize(manager: HTNDomainManager) -> void:
	super(manager)

func get_node_name() -> String:
	return "Root Node"

func validate_self() -> String:
	return ""
