class_name HTNPlanner
extends Node
## This is a script attached to the HTNPlanner node intended to be added as a child
## of an [i]agent[/i].
##
## The purpose of this node is to function similar to a compiler/interpreter. After
## given a [member domain_name] and the function [method handle_planning] called,
## the planner will take over and determine based of the [param world_state] what
## is the best course of action to take.

## Emits on when the plan generated finishes completely.[br]
## [b]IMPORTANT:[/b] You don't need to emit this signal. The planner will emit
## this for you.
signal finished	# Emits success state

## Used to stop the HTN Planner from executing tasks.[br]
## You can use this as a reactionary reponse by outside forces such as when your
## agent get's hit and you must handle that.
signal interrupt_plan	# Stops the current plan

## Used to select the HTN Domain from the HTN Database of Domain behaviors.
@export var domain_name: StringName = ""
@export_group("Debugging Options")
## Used to enable debugging print statements in the console.
@export var enable_debugging := false

@onready var _state_manager: HTNStateManager = %StateManager

var _is_planning := false

func _ready() -> void:
	assert(not domain_name.is_empty(), "You forgot to select a domain silly. :D")
	interrupt_plan.connect(_state_manager.on_interrupt)

func _physics_process(_delta: float) -> void:
	_state_manager.update(domain_name)

## You can call this to check if the HTN Planner is currently generating and
## excuting a plan for the agent.
func is_running() -> bool:
	return _is_planning

## This is the core function. This tells the HTN Planner to begin planning and
## execute the planned actions once finished if applicable.[br]
## [color=yellow][b]Enable [member enable_debugging] to check if it failed planning.[/b][/color][br][br]
##
## [param agent]: This is a refrence to the node that you would consider as your
## NPC, AI, Enemy, or a HTN controlled node. This is intended to be the parent of
## [i]this[/i] node.[br][br]
##
## [param world_state]: This is a dictionary of all information you believe your
## agent needs to complete its tasks/plan to complete.
##
## [codeblock]
## @export var home: Marker2D
## @onready var htn_planner: HTNPlanner = %HTNPlanner
##
## func _ready() -> void:
##   var world_states: Dictionary = {
##     "RNG" : randi_range(0, 100),
##     "DistanceToPlayer": global_position.distance_to(GlobalAutoload.player.global_position),
##     "PlayerLocation": GlobalAutoload.player.global_position,
##     "HomeLocation": home.global_position
##   }
##
##   htn_planner.handle_planning(self, world_states)
## [/codeblock]
func handle_planning(agent: Node, world_state: Dictionary) -> void:
	_is_planning = true
	var plan := generate_plan(world_state)
	if plan.is_empty():
		_is_planning = false
		if enable_debugging: print("Failed plan generation")
	else:
		_state_manager.start(agent, plan, world_state)

## [b]IMPORTANT:[/b] This is used internally for the planner, but also is available
## for your use in the case of [b]debugging[/b] on why the HTN Planner could not
## plan using your created HTN Domain.[br]
## [color=red]This will NOT have the agent executing tasks.[/color]
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
