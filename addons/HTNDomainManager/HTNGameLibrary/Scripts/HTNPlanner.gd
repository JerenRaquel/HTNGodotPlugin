class_name HTNPlanner
extends Node

enum PlanState { IDLE, SETUP, RUN, WAIT, EFFECT, FINISHED }

signal finished	# Emits success state
signal interrupt_plan	# Stops the current plan

@export var domain: HTNDomain
@export_group("Debugging Options")
@export var enable_debugging := false

var _primitive_library := {}
var _plan: Array[StringName]
var _agent: Node
var _world_state_plan_copy: Dictionary
var _running_plan := false
var _plan_state: PlanState = PlanState.IDLE
var _current_task: StringName

var is_planning := false

func _ready() -> void:
	for primitive_key: String in domain["required_primitives"]:
		var task: HTNPrimitiveTask = _load_primitive_resource(domain["required_primitives"][primitive_key])
		_primitive_library[primitive_key] = task
		if task.requires_awaiting:
			task.finished_operation.connect( func(): _plan_state = PlanState.EFFECT )

	interrupt_plan.connect(
		func():
			if _plan_state != PlanState.WAIT: return

			_plan_state = PlanState.IDLE
			_running_plan = false
			is_planning = false
			finished.emit()
	)

func _physics_process(_delta: float) -> void:
	if not _running_plan: return

	match _plan_state:
		PlanState.IDLE: pass
		PlanState.SETUP:
			_current_task = _plan.pop_back()
			_plan_state = PlanState.RUN
		PlanState.RUN:
			if _current_task in _primitive_library:
				var task: HTNPrimitiveTask = _primitive_library[_current_task]
				task.run_operation(_agent, _world_state_plan_copy)
				if task.requires_awaiting:
					_plan_state = PlanState.WAIT
					return
			_plan_state = PlanState.EFFECT
		PlanState.WAIT: pass
		PlanState.EFFECT:
			if _current_task in _primitive_library:
				var task: HTNPrimitiveTask = _primitive_library[_current_task]
				task.apply_effects(_world_state_plan_copy)
			else:	# Apply Effects from Applicator Node
				domain.apply_effects(_current_task, _world_state_plan_copy)
			_plan_state = PlanState.FINISHED
		PlanState.FINISHED:
			if enable_debugging: print(_agent, "::Finished Task Operation: ", _current_task)
			if _plan.is_empty():
				_plan_state = PlanState.IDLE
				_running_plan = false
				is_planning = false
				finished.emit()
			else:
				_plan_state = PlanState.SETUP

func handle_planning(agent: Node, world_state: Dictionary) -> void:
	is_planning = true
	var plan := generate_plan(world_state)
	if plan.is_empty():
		is_planning = false
		if enable_debugging: print("Failed plan generation")
	else:
		_running_plan = true
		_agent = agent
		_plan = plan
		_world_state_plan_copy = world_state
		_plan_state = PlanState.SETUP

func generate_plan(world_states: Dictionary) -> Array[StringName]:
	var world_state_copy := world_states.duplicate(true)
	var tasks_to_process: Array[StringName] = []
	var final_plan: Array[StringName] = []
	var history_stack: Array[Dictionary] = []
	var visited_methods: Array[StringName] = []

	tasks_to_process.push_back(domain["root_key"])

	while not tasks_to_process.is_empty():
		var task_key: StringName = tasks_to_process.pop_back()

		if task_key in domain["compounds"]:
			var valid_method_data := domain.get_task_chain_from_valid_method(
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
					if task_key == domain["root_key"]:
						# Back at the root with nothing to roll back to
						push_warning("Failed plan generations...")
						return []
			else:	# Valid
				# Record a backup
				_record_decomposition_task(task_key, history_stack, tasks_to_process, final_plan, world_state_copy)
				# Queue tasks to be processed
				for task_name: StringName in valid_method_data["task_chain"]:
					tasks_to_process.push_back(task_name)
		elif task_key in domain["required_primitives"]:
			_primitive_library[task_key].apply_effects(world_state_copy)
			_primitive_library[task_key].apply_expected_effects(world_state_copy)
			final_plan.push_back(task_key)
		elif task_key in domain["effects"]:
			domain.apply_effects(task_key, world_states)
			final_plan.push_back(task_key)
		else:
			assert(false, "So like uhh... " + task_key + " isn't something that is in the domain...")

	return final_plan

func _roll_back(
		history_stack: Array[Dictionary], tasks_to_process: Array[StringName],
		final_plan: Array[StringName], world_state: Dictionary) -> bool:
	if history_stack.is_empty(): return false	# Nothing to roll back

	var past_state := history_stack.pop_back()
	tasks_to_process.assign(past_state["tasks_to_process"])
	final_plan.assign(past_state["final_plan"])
	var keys := (past_state["world_state"] as Dictionary).keys()
	for key: StringName in keys:
		world_state[key] = past_state["world_state"][key]
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
