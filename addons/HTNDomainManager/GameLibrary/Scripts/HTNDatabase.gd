extends Node

const HTN_REFERENCE_FILE = preload("res://addons/HTNDomainManager/Data/ReferenceFiles/HTNReferenceFile.tres")

@onready var domains: Dictionary = HTN_REFERENCE_FILE["domains"]
@onready var tasks: Dictionary = HTN_REFERENCE_FILE["tasks"]

func register(domain_name: StringName, callable: Callable) -> void:
	#var task_names: Array = HTN_DOMAIN_FILE_REF["domains"][domain_name]["required_primitives"].keys()
	#for task_name: StringName in task_names:
		#assert(task_name in HTN_TASK_REF["primitive_tasks"])
		#HTN_TASK_REF["primitive_tasks"][task_name].finished_operation.connect(callable)
	pass

func unregister(domain_name: StringName, callable: Callable) -> void:
	#var task_names: Array = HTN_DOMAIN_FILE_REF["domains"][domain_name]["required_primitives"].keys()
	#for task_name: StringName in task_names:
		#assert(task_name in HTN_TASK_REF["primitive_tasks"])
		#HTN_TASK_REF["primitive_tasks"][task_name].finished_operation.connect(callable)
	pass

func apply_effects(current_domain_key: StringName, effect_node_key: StringName, world_state_data: Dictionary) -> void:
	var effect_data: Dictionary = domains[current_domain_key]["effects"][effect_node_key]["data"]
	for data_key: StringName in effect_data.keys():
		var value = effect_data[data_key]["value"]

		if effect_data[data_key]["type_id"] == 6:	# World State Key Type
			assert(
				world_state_data.has(value),
				"Attempt to alter a world state with a non-existent world state::" + value
			)
			world_state_data[data_key] = world_state_data[value]
		else:
			world_state_data[data_key] = value

func get_task_chain_from_valid_method(
		current_domain_key: StringName,
		compound_node_key: StringName,
		failed_method_paths: Array[StringName],
		world_state_data: Dictionary) -> Dictionary:	# {method_node_key: StringName, "task_chain": Array[StringName]}
	var method_branches: Array\
		= domains[current_domain_key]["compounds"][compound_node_key]["method_branches"]

	for method_key: StringName in method_branches:
		if method_key in failed_method_paths: continue

		var method: Dictionary = domains[current_domain_key]["methods"][method_key]
		if _evaluate(method["method_data"], world_state_data):
			return {
				"method_key": method_key,
				"task_chain": method["task_chain"]
			}

	return {}	# Fail

func _evaluate(method_data: Dictionary, world_state_data: Dictionary) -> bool:
	if method_data.has("AlwaysTrue"): return true

	# Evaluate every condition in the method
	for world_state_key: String in method_data:
		if world_state_key not in world_state_data: return false

		var world_state_data_value = world_state_data[world_state_key]
		var rhs = method_data[world_state_key]["value"]
		var eval_world_states: bool = (method_data[world_state_key]["type_id"] == 6)
		if eval_world_states:
			# Invalid indexing
			if world_state_data_value not in world_state_data:
				push_error(
					"Attempting to access " + world_state_data_value + " in world state data.\nReturning false."
				)
				return false
			else:
				rhs = world_state_data[method_data[world_state_key]["value"]]

		var compare_id: int = method_data[world_state_key]["compare_id"]
		if _evaluate_compare(compare_id, world_state_data_value, rhs):
			continue
		else:
			# Un-true condition
			return false

	# All conditions are true
	return true

func _evaluate_compare(compare_id: int, lhs, rhs) -> bool:
	match compare_id:
		0:	# Greater Than | >
			return lhs > rhs
		1:	# Less Than | <
			return lhs < rhs
		2:	# Equal To | ==
			return lhs == rhs
		3:	# Greater Than or Equal To | >=
			return lhs >= rhs
		4:	# Less Than or Equal To | <=
			return lhs <= rhs
		_: return false	# Unknown
