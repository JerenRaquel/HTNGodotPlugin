@tool
class_name SimulationManager
extends VBoxContainer

const SIM_LINE = preload("res://addons/HTNDomainManager/PluginSystem/SimulationPanel/sim_line.tscn")

var _manager: HTNDomainManager
var _states_parent: VBoxContainer

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	_states_parent = %States
	_update_visiable_states("")

func _update_visiable_states(filter: String) -> void:
	var search_key := filter.to_lower()
	for sim_line: HBoxContainer in _states_parent.get_children():
		var sim_line_key: String = sim_line._world_state_key.to_lower()
		if filter == "" or sim_line_key.contains(search_key):
			sim_line.show()
		else:
			sim_line.hide()

func _validate_world_states() -> bool:
	for sim_line: HBoxContainer in _states_parent.get_children():
		if sim_line._world_state_key.is_empty(): return false

	return true

func _compile_world_states() -> Dictionary:
	var data := {}

	for sim_line: HBoxContainer in _states_parent.get_children():
		var line_data: Dictionary = sim_line.get_data()
		data[line_data["key"]] = line_data["value"]

	return data

func _generate_path(world_states: Dictionary) -> Array:
	var world_state_copy: Dictionary = world_states.duplicate(true)
	var loaded_primitives: Dictionary = {}
	var final_plan: Array[StringName] = []	# [(node_key (StringName))...]
	var visited_node_keys: Array[StringName] = []	# [(node_key (StringName))...]
	var current_node_key: StringName = _manager.graph_handler.get_root_key()

	_load_primitives(loaded_primitives)

	while _manager.graph_handler.has_connections_from_output(current_node_key):
		if current_node_key in visited_node_keys:
			return [final_plan, true]	# Hit recursion
		final_plan.push_back(current_node_key)
		visited_node_keys.push_back(current_node_key)

		var node = _manager.graph_handler.nodes[current_node_key]

		if node is HTNRootNode or node is HTNCompoundNode:
			var connected_nodes:Array[StringName] =\
				 _manager.graph_handler.get_connected_nodes_from_output(current_node_key)
			var next_node_key: Array[StringName] =\
				_get_next_node_from_methods(connected_nodes, world_state_copy)
			if next_node_key.is_empty():
				# Path failed roll back
				var reverted := false
				while not final_plan.is_empty():
					var last_node_key := final_plan.pop_back()
					var last_node = _manager.graph_handler.nodes[last_node_key]
					if last_node is HTNRootNode or last_node == HTNCompoundNode:
						current_node_key = last_node_key
						reverted = true
						break
				if reverted:
					continue
				else:
					return [[], false]	# Return empty, there were no paths to take
			else:
				final_plan.push_back(next_node_key[0])	# Method Node
				visited_node_keys.push_back(next_node_key[0])	# Method Node
				current_node_key = next_node_key[1]	# Connected Node
		elif node is HTNPrimitiveNode:
			(loaded_primitives[current_node_key] as HTNPrimitiveTask).apply_expected_effects(world_state_copy)
			var connected_nodes:Array[StringName] =\
				 _manager.graph_handler.get_connected_nodes_from_output(current_node_key)
			current_node_key = connected_nodes[0]
		elif node is HTNApplicatorNode:
			_apply_effects(node.effect_data, world_state_copy)
			var connected_nodes:Array[StringName] =\
				 _manager.graph_handler.get_connected_nodes_from_output(current_node_key)
			current_node_key = connected_nodes[0]
		else:
			return [final_plan, false]	# Unknown node; stop early

	final_plan.push_back(current_node_key)
	return [final_plan, true]

func _load_primitives(loaded_primitives: Dictionary) -> void:
	var primitives: Dictionary = _manager.graph_handler.get_every_primitive()

	for primitive_key: StringName in primitives.keys():
		if primitive_key in loaded_primitives: continue

		var task_name: StringName = primitives[primitive_key]
		var node: HTNPrimitiveNode = _manager.graph_handler.nodes[primitive_key]
		var stripped_name: String = node.get_node_name().replace("Primitive - ", "")

		# Load resource
		var resource_path: String = _manager.serializer.get_resource_path_from_name(stripped_name)
		if resource_path == "":
			_manager.validation_handler.send_error_generic(
				"File path doesn't exist for " + stripped_name
			)
		loaded_primitives[primitive_key] = load(resource_path).duplicate()

func _get_next_node_from_methods(connected_methods: Array[StringName], world_state: Dictionary) -> Array[StringName]:
	connected_methods.sort_custom(_sort_method_keys)

	for node_key: StringName in connected_methods:
		var node = _manager.graph_handler.nodes[node_key]
		if not node is HTNMethodNode: continue

		if node is HTNMethodNodeAlwaysTrue:
			var next_keys := _manager.graph_handler.get_connected_nodes_from_output(node_key)
			if next_keys.is_empty():
				return []
			else:
				return [node_key, next_keys[0]]
		elif _evaluate((node as HTNMethodNode).condition_data, world_state):
			var next_keys := _manager.graph_handler.get_connected_nodes_from_output(node_key)
			if next_keys.is_empty():
				return []
			else:
				return [node_key, next_keys[0]]

	return []

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

func _apply_effects(effect_data: Dictionary, world_state_data: Dictionary) -> void:
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

func _sort_method_keys(method_a: StringName, method_b: StringName) -> bool:
	var node_a: HTNMethodNode = _manager.graph_handler.nodes[method_a]
	var node_b: HTNMethodNode = _manager.graph_handler.nodes[method_b]

	return node_a.get_priority() > node_b.get_priority()

func _on_add_state_button_pressed() -> void:
	var effect_line_instance := SIM_LINE.instantiate()
	_states_parent.add_child(effect_line_instance)
	effect_line_instance.initialize()

func _on_search_bar_text_changed(new_text: String) -> void:
	_update_visiable_states(new_text)

func _on_run_button_pressed() -> void:
	if not _validate_world_states():
		_manager.validation_handler\
			.send_error_generic(_manager.validation_handler.SIM_INVALID_STATES, true)
	_manager.graph_handler.clear_node_colors()
	var plan_data: Array = _generate_path(_compile_world_states())
	_manager.graph_handler.color_node_path(plan_data[0], plan_data[1])
	if not plan_data[0].is_empty() and plan_data[1]:
		_manager.validation_handler.send_message(
			"HTN can potentially generate a valid plan.",
			_manager.validation_handler.MessageType.OK,
			true
		)
	else:
		_manager.validation_handler.send_error_generic(
			"Not enough method paths to determine a potential plan based on world states given."
		)
