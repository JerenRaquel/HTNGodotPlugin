extends Node
## [color=red][b]This is only used by the HTN Planner. DO NOT USE.[/b][/color]

const HTN_REFERENCE_FILE = preload("res://addons/HTNDomainManager/Data/HTNReferenceFile.tres")

# { domain_key : domain_resource (HTNDomain) }
var _domains: Dictionary
# { task_key : task_resource (HTNTask) }
var _tasks: Dictionary
var _HTN_core_module_library: HTNCoreModuleLibrary

func _ready() -> void:
	_domains = HTN_REFERENCE_FILE["domains"]
	_tasks = HTN_REFERENCE_FILE["tasks"]
	_HTN_core_module_library = HTNCoreModuleLibrary.new()

func domain_has(current_domain_name: StringName, type: String, node_key: StringName) -> bool:
	if _domains[current_domain_name][type].is_empty(): return false

	if type == "task_map":
		return _domains[current_domain_name]["task_map"].has(node_key)
	return node_key in _domains[current_domain_name][type]

func is_domain_root(current_domain_key: StringName, node_key: StringName) -> bool:
	return node_key == _domains[current_domain_key]["root_key"]

func get_domain_key(node_key) -> StringName:
	return _domains[node_key]

func get_root_key_from_current_domain(current_domain_name: StringName) -> StringName:
	return _domains[current_domain_name]["root_key"]

func has_task(current_domain_name: StringName, task_key: StringName) -> bool:
	var task_name: String = _domains[current_domain_name]["task_map"].get(task_key, "")
	if task_name.is_empty(): return false
	return task_name in _tasks

func get_task(current_domain_name: StringName, task_key: StringName) -> HTNTask:
	var task_name: String = _domains[current_domain_name]["task_map"][task_key]
	return _tasks[task_name]

func get_task_name(current_domain_name: StringName, task_key: StringName) -> String:
	var task_name: String = _domains[current_domain_name]["task_map"].get(task_key, "")
	if task_name.is_empty(): return "Non-Task: "+task_key
	return task_name

func apply_effects(current_domain_key: StringName, effect_node_key: StringName, world_state_data: Dictionary) -> void:
	var effect_data: Dictionary = _domains[current_domain_key]["effects"][effect_node_key]
	for world_state_key: StringName in effect_data.keys():
		var value = effect_data[world_state_key]["Value"]

		if effect_data[world_state_key]["TypeID"] == 6:	# World State Key Type
			assert(
				world_state_data.has(value),
				"Attempt to alter a world state with a non-existent world state::" + value
			)
			world_state_data[world_state_key] = world_state_data[value]
		else:
			world_state_data[world_state_key] = value

func apply_module(current_domain_key: StringName, module_node_key: StringName, world_state_data: Dictionary) -> void:
	var module_data: Dictionary = _domains[current_domain_key]["modules"][module_node_key]
	var function_name: String = module_data[0]
	assert(_HTN_core_module_library.has_method(function_name),
		"Module Key: "+module_node_key+" attempting to call non-existing function: "+function_name+"."
	)
	var node_data: Dictionary = module_data[1]
	_HTN_core_module_library.call(function_name, world_state_data, node_data)

func get_task_chain_from_valid_method(
		current_domain_name: StringName,
		compound_node_key: StringName,
		failed_method_paths: Array[StringName],
		world_state_data: Dictionary) -> Dictionary:	# {method_node_key: StringName, "task_chain": Array[StringName]}
	var method_branches: Array\
		= _domains[current_domain_name]["splits"][compound_node_key]

	for method_key: StringName in method_branches:
		if method_key in failed_method_paths: continue

		var method: Dictionary = _domains[current_domain_name]["methods"][method_key]
		if _evaluate(method["method_data"], world_state_data):
			return {
				"method_key": method_key,
				"task_chain": method["task_chain"]
			}

	return {}	# Fail

func _evaluate(method_data: Dictionary, world_state_data: Dictionary) -> bool:
	# Data is only: { "AlwaysTrue": true }
	if method_data.has("AlwaysTrue"): return true

	# Evaluate every condition in the method
	for world_state_key: String in method_data:
		if world_state_key not in world_state_data: return false

		var world_state_data_value = world_state_data[world_state_key]
		var rhs = method_data[world_state_key]["Value"]
		var compare_ID: int = method_data[world_state_key]["CompareID"]
		if compare_ID == 5:	# Range
			if _evaluate_range(
				method_data[world_state_key]["RangeID"],
				method_data[world_state_key]["RangeInclusivity"],
				world_state_data_value,
				rhs
			):
				return true
			else:
				continue
		else:
			if method_data[world_state_key]["SingleID"] == 6:	# World State
				# Invalid indexing
				if world_state_data_value not in world_state_data:
					push_error(
						"Attempting to access " + world_state_data_value + " in world state data.\nReturning false."
					)
					return false
				else:
					rhs = world_state_data[method_data[world_state_key]["value"]]
			if _evaluate_compare(compare_ID, world_state_data_value, rhs):
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

func _evaluate_range(range_ID: int, range_inclusivity: Array, world_state_data_value, condition_value) -> bool:
	var rhs_state := false
	if range_ID == 0:	#Int
		# RHS
		if range_inclusivity[1] and world_state_data_value <= (condition_value as Vector2i).y:
				rhs_state = true
		elif not range_inclusivity[1] and world_state_data_value < (condition_value as Vector2i).y:
				rhs_state = true
		# LHS
		if range_inclusivity[0] and world_state_data_value >= (condition_value as Vector2i).x and rhs_state:
				return true
		elif not range_inclusivity[0] and world_state_data_value > (condition_value as Vector2i).x and rhs_state:
				return true
		return false
	else:	# Float
		# RHS
		if range_inclusivity[1] and world_state_data_value <= (condition_value as Vector2).y:
				rhs_state = true
		elif not range_inclusivity[1] and world_state_data_value < (condition_value as Vector2).y:
				rhs_state = true
		# LHS
		if range_inclusivity[0] and world_state_data_value >= (condition_value as Vector2).x and rhs_state:
				return true
		elif not range_inclusivity[0] and world_state_data_value > (condition_value as Vector2).x and rhs_state:
				return true
		return false
