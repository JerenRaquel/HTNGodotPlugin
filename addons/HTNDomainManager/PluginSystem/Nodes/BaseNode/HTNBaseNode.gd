@tool
class_name HTNBaseNode
extends GraphNode

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager

func get_node_name() -> String:
	return ""

# Return value:
#	On valid: return "" (and empty string)
#	On invalid: return an error message string
func validate_self() -> String:
	return "HTN Base Node Default Error Message"

func load_data(data: Dictionary) -> void:
	pass
