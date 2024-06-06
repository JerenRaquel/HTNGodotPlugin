class_name HTNPlanner
extends Node

signal finished	# Emits success state
signal interrupt_plan	# Stops the current plan

@export var domain_name: StringName
@export_group("Debugging Options")
@export var enable_debugging := false
@export var suppress_warnings := true

@onready var state_manager: HTNStateManager = %StateManager

var is_planning := false

func _ready() -> void:
	interrupt_plan.connect(state_manager.on_interrupt)

func _physics_process(_delta: float) -> void:
	state_manager.update(domain_name)

## This function is used to let the HTN Planner know the current operation is
## finished running as required by the HTNTask's [member requires_awaiting]
## member.
func report_task_finished() -> void:
	state_manager.set_state(state_manager.PlanState.EFFECT)

func handle_planning(agent: Node, world_state: Dictionary) -> void:
	is_planning = true
	var plan := generate_plan(world_state)
	if plan.is_empty():
		is_planning = false
		if enable_debugging: print("Failed plan generation")
	else:
		state_manager.start(agent, plan, world_state)

func generate_plan(world_states: Dictionary) -> Array[StringName]:
	return _generate_plan_from_domain(domain_name, world_states)[0]

# Returns: [final_plan, world_states]
func _generate_plan_from_domain(current_domain_name: StringName, world_states: Dictionary) -> Array:
	var world_state_copy := world_states.duplicate(true)
	var tasks_to_process: Array[StringName] = []
	var final_plan: Array[StringName] = []
	var history_stack: Array[Dictionary] = []
	var visited_methods: Array[StringName] = []

	tasks_to_process.push_back(HTNDatabase.domains[current_domain_name]["root_key"])

	while not tasks_to_process.is_empty():
		var task_key: StringName = tasks_to_process.pop_front()
		if task_key in HTNDatabase.domains[current_domain_name]["splits"]:
			push_warning("Found splitter")
			var valid_method_data: Dictionary = HTNDatabase.get_task_chain_from_valid_method(
				current_domain_name,
				task_key,
				visited_methods,
				world_state_copy
			)
			push_warning(valid_method_data)
			# Record Branch
			var key: StringName = valid_method_data.get("method_key", task_key)
			if key not in visited_methods: visited_methods.push_back(key)

			if valid_method_data.is_empty() or valid_method_data["task_chain"].is_empty():	# Not valid
				# OHHHHHHHHH EVERYTHING IS ON FIRE! GO BACK! GO BACK! GO BA- *LOUD CRASH NOISES*
				if not _roll_back(history_stack, tasks_to_process, final_plan, world_state_copy):
					# Failed to find anything to roll back to
					if task_key == HTNDatabase.domains[current_domain_name]["root_key"]:
						# Back at the root with nothing to roll back to
						push_warning("Failed plan generations...")
						return []
			else:	# Valid
				# Record a backup
				_record_decomposition_task(task_key, history_stack, tasks_to_process, final_plan, world_state_copy)
				# Queue tasks to be processed
				for task_name: StringName in valid_method_data["task_chain"]:
					tasks_to_process.push_back(task_name)
		elif task_key in HTNDatabase.domains[current_domain_name]["required_tasks"]:
			HTNDatabase.tasks[task_key].apply_effects(world_state_copy)
			HTNDatabase.tasks[task_key].apply_expected_effects(world_state_copy)
			final_plan.push_back(task_key)
		elif task_key in HTNDatabase.domains[current_domain_name]["effects"]:
			HTNDatabase.apply_effects(current_domain_name, task_key, world_states)
			final_plan.push_back(task_key)
		elif task_key in HTNDatabase.domains[current_domain_name]["required_domains"]:
			var generated_data: Array = _generate_plan_from_domain(
				HTNDatabase.domains[task_key],
				world_state_copy
			)
			# Check if plan is empty
			if generated_data[0].is_empty():	# Failed
				# OHHHHHHHHH EVERYTHING IS ON FIRE! GO BACK! GO BACK! GO BA- *LOUD CRASH NOISES*
				while true:
					if not _roll_back(history_stack, tasks_to_process, final_plan, world_state_copy):
						# Failed to find anything to roll back to
						# Back at the root with nothing to roll back to
						return []
					if tasks_to_process.is_empty():
						# Nothing to process
						return []

					var next_task: StringName = tasks_to_process.back()
					if next_task in HTNDatabase.domains[current_domain_name]["splits"]: break

			else:	# Valid
				# Record a backup
				_record_decomposition_task(task_key, history_stack, tasks_to_process, final_plan, world_state_copy)
				# Set the world states
				world_state_copy.merge(generated_data[1], true)
				# Add tasks to the final plan
				for task_name: StringName in generated_data[0]:
					final_plan.push_back(task_name)
		else:
			assert(false, "So like uhh... " + task_key + " isn't something that is in the current_domain...")

	return [final_plan, world_state_copy]

func _roll_back(
		history_stack: Array[Dictionary], tasks_to_process: Array[StringName],
		final_plan: Array[StringName], world_state: Dictionary) -> bool:
	if history_stack.is_empty(): return false	# Nothing to roll back

	var past_state := history_stack.pop_back()
	tasks_to_process.assign(past_state["tasks_to_process"])
	final_plan.assign(past_state["final_plan"])
	world_state.clear()
	world_state.merge(past_state["world_state"], true)
	return true	# Success

func _record_decomposition_task(
		task: StringName, history_stack: Array[Dictionary], tasks_to_process: Array[StringName],
		final_plan: Array[StringName], world_state: Dictionary) -> void:
	var tasks_to_process_copy := tasks_to_process.duplicate()
	tasks_to_process_copy.push_back(task)
	history_stack.push_back({
		"tasks_to_process": tasks_to_process_copy,
		"final_plan": final_plan.duplicate(),
		"world_state": world_state.duplicate(true)
	})
