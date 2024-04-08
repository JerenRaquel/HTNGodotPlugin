class_name HTNDomain
extends Resource

# The start of the tree
@export var root_key: StringName

# {task_name (StringName) : resource_path (string)}
@export var required_primitives: Dictionary

# {domain_name (StringName) : resource_path (string)}
@export var required_domains: Dictionary

# {compound_node_key (StringName) : { "nick_name": "" (String), "method_branches": [(method_node_key: StringName)...] }}
@export var compounds: Dictionary

# { method_node_key (StringName) : { "nick_name": name (String), "method_data": data (Dictionary), "task_chain": [(task_name: StringName)...]}}
@export var methods: Dictionary

# { effect_node_key (StringName) : { "nick_name: name (String), "data": { "world_state_key" : {"type_id": int, "value": any} } } }
@export var effects: Dictionary

func apply_effects(effect_node_key: StringName, world_state_data: Dictionary) -> void:
	for data_key: StringName in effects[effect_node_key]["data"].keys():
		var value = effects[effect_node_key]["data"][data_key]["value"]

		if effects[effect_node_key]["data"][data_key]["type_id"] == 6:	# World State Key Type
			assert(
				world_state_data.has(value),
				"Attempt to alter a world state with a non-existent world state::" + value
			)
			world_state_data[data_key] = world_state_data[value]
		else:
			world_state_data[data_key] = value

func get_task_chain_from_valid_method(
		compound_node_key: StringName,
		failed_method_paths: Array[StringName],
		world_state_data: Dictionary) -> Dictionary:	# {method_node_key: StringName, "task_chain": Array[StringName]}
	var method_branches: Array[StringName] = compounds[compound_node_key]["method_branches"]

	for method_key: StringName in method_branches:
		if method_key in failed_method_paths: continue

		if _evaluate(methods[method_key]["method_data"], world_state_data):
			return {
				"method_key": method_key,
				"task_chain": methods[method_key]["task_chain"]
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
