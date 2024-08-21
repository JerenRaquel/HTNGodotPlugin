extends Node
## [color=red][b]This is only used by the HTN Planner. DO NOT USE.[/b][/color]

const TASK_PATH := "res://addons/HTNDomainManager/Data/Tasks/"
const DOMAIN_PATH := "res://addons/HTNDomainManager/Data/Domains/"

# { domain_name : domain_resource (HTNDomain) }
var _domains: Dictionary
# { task_key : task_resource (HTNTask) }
var _tasks: Dictionary
var _HTN_core_module_library: HTNCoreModuleLibrary

func _ready() -> void:
	_domains = _get_all_domain_files()
	_tasks = _get_all_task_files()
	_HTN_core_module_library = HTNCoreModuleLibrary.new()

func is_quit_early(current_domain_name: StringName, task_key: StringName) -> bool:
	return task_key in _domains[current_domain_name]["quits"]

func domain_exists(domain_name: StringName) -> bool:
	return domain_name in _domains

func domain_has(current_domain_name: StringName, type: String, node_key: StringName) -> bool:
	if _domains[current_domain_name][type].is_empty(): return false

	if type == "task_map":
		return _domains[current_domain_name]["task_map"].has(node_key)
	elif type == "domain_map":
		return _domains[current_domain_name]["domain_map"].has(node_key)
	return node_key in _domains[current_domain_name][type]

func is_domain_root(current_domain_key: StringName, node_key: StringName) -> bool:
	return node_key == _domains[current_domain_key]["root_key"]

func get_domain_name_from_key(current_domain_name: StringName, node_key) -> StringName:
	return _domains[current_domain_name]["domain_map"].get(node_key, "")

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
	if task_key in _domains[current_domain_name]["quits"]:
		return "Quit Early"
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

func _evaluate(method_data: Array[Array], world_state_data: Dictionary) -> bool:
	# Data is only: [["AlwaysTrue"]]
	if method_data.size() == 1:
		if method_data[0].has("AlwaysTrue"): return true

	# Evaluate every condition in the method
	for condition: Array in method_data:
		if condition.size() == 3:	# Standard Check
			var lhs_result: Array = _get_world_state_or_value(condition[0], world_state_data)
			if not lhs_result[0]: return false	# Invalid Data

			var rhs_result: Array = _get_world_state_or_value(condition[2], world_state_data)
			if not rhs_result[0]: return false	# Invalid Data

			if _evaluate_compare(condition[1], lhs_result[1], rhs_result[1]):
				continue
			else:
				# Un-true condition
				return false
		else:	# Range Check
			var lhs_result: Array = _get_world_state_or_value(condition[0], world_state_data)
			if not lhs_result[0]: return false	# Invalid Data

			var mid_result: Array = _get_world_state_or_value(condition[2], world_state_data)
			if not mid_result[0]: return false	# Invalid Data

			var rhs_result: Array = _get_world_state_or_value(condition[4], world_state_data)
			if not rhs_result[0]: return false	# Invalid Data

			if _evaluate_compare(condition[1], lhs_result, mid_result)\
					and _evaluate_compare(condition[3], mid_result, rhs_result):
				continue
			else:
				# Un-true condition
				return false

	# All conditions are true
	return true

# [is_valid, value]
func _get_world_state_or_value(token: Variant, world_state_data: Dictionary) -> Array:
	if token is String and token.begins_with("$"):
		var world_state_key: String = token.substr(1)
		if world_state_key not in world_state_data: return [false, null]
		return [true, world_state_data[world_state_key]]
	else:
		return [true, token]

func _evaluate_compare(compare_id: String, lhs, rhs) -> bool:
	match compare_id:
		">":
			return lhs > rhs
		"<":
			return lhs < rhs
		"==":
			return lhs == rhs
		"!=":
			return lhs != rhs
		">=":
			return lhs >= rhs
		"<=":
			return lhs <= rhs
		_: return false	# Unknown

func _get_all_domain_files() -> Dictionary:
	var domain_files: Dictionary = {}
	var files: PackedStringArray = DirAccess.get_files_at(DOMAIN_PATH)
	for file: String in files:
		var file_name: String = file.replace(".tres", "").replace(".remap", "")
		if file_name in domain_files: continue
		domain_files[file_name] = load(DOMAIN_PATH + file.replace(".remap", ""))
	return domain_files

func _get_all_task_files() -> Dictionary:
	var task_files: Dictionary = {}
	var files: PackedStringArray = DirAccess.get_files_at(TASK_PATH)
	for file: String in files:
		var file_name: String = file.replace(".tres", "").replace(".remap", "")
		if file_name in task_files: continue
		task_files[file_name] = load(TASK_PATH + file.replace(".remap", ""))
	return task_files
