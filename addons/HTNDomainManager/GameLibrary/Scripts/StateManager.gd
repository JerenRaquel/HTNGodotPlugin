class_name HTNStateManager
extends Node
## [color=red][b]This is only used by the HTN Planner. DO NOT USE.[/b][/color]

enum PlanState { IDLE, SETUP, RUN, WAIT, EFFECT, FINISHED }

@onready var htn_planner: HTNPlanner = $".."

var _plan_state: PlanState = PlanState.IDLE
var _running_plan := false
var _current_task: StringName
var _plan: Array[StringName]
var _world_state_copy: Dictionary
var _agent: Node

func start(agent: Node, plan: Array[StringName], world_state_copy: Dictionary) -> void:
	_agent = agent
	_plan = plan
	_world_state_copy = world_state_copy
	_plan_state = PlanState.SETUP
	_running_plan = true

func update(domain_name: StringName) -> void:
	if not _running_plan: return

	match _plan_state:
		PlanState.IDLE: pass	# Intended to do nothing
		PlanState.SETUP: _setup()
		PlanState.RUN: _run()
		PlanState.WAIT: pass	# Intended to do nothing
		PlanState.EFFECT: _effect(domain_name)
		PlanState.FINISHED: _finished()

func on_interrupt() -> void:
	if _plan_state != PlanState.WAIT: return

	_plan_state = PlanState.IDLE
	_running_plan = false
	htn_planner._is_planning = false
	htn_planner.finished.emit()

func _setup() -> void:
	_current_task = _plan.pop_front()
	_plan_state = PlanState.RUN

func _run() -> void:
	if _current_task in HTNDatabase.tasks:
		var task: HTNTask = HTNDatabase.tasks[_current_task]
		task.run_operation(func() -> void: _plan_state = PlanState.EFFECT, _agent, _world_state_copy)
		if task.requires_awaiting:
			_plan_state = PlanState.WAIT
			return
	_plan_state = PlanState.EFFECT

func _effect(domain_name: StringName) -> void:
	if _current_task in HTNDatabase.tasks:
		var task: HTNTask = HTNDatabase.tasks[_current_task]
		task.apply_effects(_world_state_copy)
	else:	# Apply Effects from Applicator Node
		HTNDatabase.apply_effects(domain_name, _current_task, _world_state_copy)
	_plan_state = PlanState.FINISHED

func _finished() -> void:
	if htn_planner.enable_debugging: print(_agent, "::Finished Task Operation: ", _current_task)
	if _plan.is_empty():
		_plan_state = PlanState.IDLE
		_current_task = ""
		_plan.clear()
		_world_state_copy.clear()
		_agent = null
		_running_plan = false
		htn_planner._is_planning = false
		htn_planner.finished.emit()
	else:
		_plan_state = PlanState.SETUP
