@tool
class_name HTNMethodNodeAlwaysTrue
extends HTNMethodNode

func initialize(manager: HTNDomainManager) -> void:
	super(manager)
	condition_data = { "AlwaysTrue": true }

func validate_self() -> String:
	return ""

func get_priority() -> int:
	return -9223372036854775808

func load_data(_data) -> void:
	# WHO? IDC
	pass
