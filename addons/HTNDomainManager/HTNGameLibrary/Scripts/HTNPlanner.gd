class_name HTNPlanner
extends Node

signal finished	# Emits success state
signal interrupt_plan	# Stops the current plan

@export var domain: HTNDomain
@export_group("Debugging Options")
@export var enable_debugging := false
@export var suppress_warnings := true

@onready var state_manager: HTNStateManager = %StateManager

var _sub_domain_library := {}
var _primitive_library := {}

var is_planning := false

func _ready() -> void:
	# Load self
	_sub_domain_library[domain["domain_name"]] = domain
	# Load all valid sub domains -- load sub domains in root
	for domain_name: StringName in domain["required_domains"]:
		if domain_name in _sub_domain_library: continue
		# Keep Digging
		_load_sub_domains(domain_name, domain["required_domains"][domain_name])

	for domain_name: StringName in _sub_domain_library.keys():
		var sub_domain: HTNDomain = _sub_domain_library[domain_name]
		for primitive_key: String in sub_domain["required_primitives"]:
			if primitive_key in _primitive_library: continue

			var task: HTNPrimitiveTask = _load_primitive_resource(sub_domain["required_primitives"][primitive_key])
			_primitive_library[primitive_key] = task
			if task.requires_awaiting:
				task.finished_operation.connect( func(): state_manager.set_state(state_manager.PlanState.EFFECT) )

	interrupt_plan.connect(state_manager.on_interrupt)

func _physics_process(_delta: float) -> void:
	state_manager.update(domain)

func handle_planning(agent: Node, world_state: Dictionary) -> void:
	is_planning = true
	var plan := generate_plan(world_state)
	if plan.is_empty():
		is_planning = false
		if enable_debugging: print("Failed plan generation")
	else:
		state_manager.start(agent, plan, world_state)

func generate_plan(world_states: Dictionary) -> Array[StringName]:
	return _generate_plan_from_domain(domain, world_states)[0]

# Returns: [final_plan, world_states]
func _generate_plan_from_domain(current_domain: HTNDomain, world_states: Dictionary) -> Array:
	var world_state_copy := world_states.duplicate(true)
	var tasks_to_process: Array[StringName] = []
	var final_plan: Array[StringName] = []
	var history_stack: Array[Dictionary] = []
	var visited_methods: Array[StringName] = []

	while not tasks_to_process.is_empty():
		var task_key: StringName = tasks_to_process.pop_back()

		if task_key in current_domain["compounds"]:
			var valid_method_data := current_domain.get_task_chain_from_valid_method(
				task_key,
				visited_methods,
				world_state_copy
			)
			# Record Branch
			var key: StringName = valid_method_data.get("method_key", task_key)
			if key not in visited_methods: visited_methods.push_back(key)

			if valid_method_data.is_empty() or valid_method_data["task_chain"].is_empty():	# Not valid
				# OHHHHHHHHH EVERYTHING IS ON FIRE! GO BACK! GO BACK! GO BA- *LOUD CRASH NOISES*
				if not _roll_back(history_stack, tasks_to_process, final_plan, world_state_copy):
					# Failed to find anything to roll back to
					if task_key == current_domain["root_key"]:
						# Back at the root with nothing to roll back to
						push_warning("Failed plan generations...")
						return []
			else:	# Valid
				# Record a backup
				_record_decomposition_task(task_key, history_stack, tasks_to_process, final_plan, world_state_copy)
				# Queue tasks to be processed
				for task_name: StringName in valid_method_data["task_chain"]:
					tasks_to_process.push_back(task_name)
		elif task_key in current_domain["required_primitives"]:
			_primitive_library[task_key].apply_effects(world_state_copy)
			_primitive_library[task_key].apply_expected_effects(world_state_copy)
			final_plan.push_back(task_key)
		elif task_key in current_domain["effects"]:
			current_domain.apply_effects(task_key, world_states)
			final_plan.push_back(task_key)
		elif task_key in current_domain["required_domains"]:
			var generated_data: Array = _generate_plan_from_domain(
				_sub_domain_library[task_key],
				world_state_copy
			)
			if generated_data.is_empty():	# Failed
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
					if next_task in current_domain["compounds"]: break

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

func _load_primitive_resource(file_path: String) -> HTNPrimitiveTask:
	assert(FileAccess.file_exists(file_path), "Primitive File Doesn't Exist: " + file_path)

	# TODO: Removed .duplicate() once project upgrades to ver 4.3
	return ResourceLoader.load(file_path).duplicate()

func _load_domain_resource(file_path: String) -> HTNDomain:
	assert(FileAccess.file_exists(file_path), "Domain File Doesn't Exist: " + file_path)

	# TODO: Remove .duplicate() once project upgrades to version 4.3
	return ResourceLoader.load(file_path).duplicate()

func _load_sub_domains(current_name: StringName, current_domain: HTNDomain) -> void:
	# Check if already loaded
	if current_name in _sub_domain_library:
		if not suppress_warnings:
			push_warning("Domain: " + current_name + " was encountered again.\nThis may lead to recursion issues.")
		return

	# Load domain
	var sub_domain: HTNDomain = _load_domain_resource(current_domain["required_domains"][current_name])
	_sub_domain_library[current_name] = sub_domain

	# Load all valid sub domains
	for domain_name: StringName in current_domain["required_domains"]:
		if domain_name in _sub_domain_library:
			if not suppress_warnings:
				push_warning("Domain: " + domain_name + " was encountered again.\nThis may lead to recursion issues.")
			continue

		_load_sub_domains(domain_name, current_domain["required_domains"][domain_name])
