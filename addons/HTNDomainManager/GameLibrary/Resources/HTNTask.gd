class_name HTNTask
extends Resource
## This is the base class that all task scripts generated by the HTNDomainManager plugin
## creates.
##
## The main purpose of this script and all script inheritting this is to allow the
## the user a way to create modular code functions or tasks. As the HTN planner
## determines what tasks it should use for the plan, it will refer to the presented
## functions.

## Tells the HTN Planner during plan execution to halt and pause at this task until
## [param HTN_finished_op_callback] function is called.[br][br]
##
## [b]IMPORTANT:[/b] If this boolean is set to true, make sure to call
## [param HTN_finished_op_callback] in the [method run_operation] function
## once the operation is finished, or the HTN Planner will never unpause.
@export var requires_awaiting := false

## During the HTN Planner execution phase, this function tells the agent what to
## do.[br][br]
##
## [param HTN_finished_op_callback]: This is a callback to be used if the task needs to
## wait for some [i]operation[/i] to finish.[br]
## [color=yellow]You should only call this if [member requires_awaiting] is true.
## This may have undefined results otherwise.[/color][br][br]
##
## [param agent]: This is a refrence to the node that you would consider as your
## NPC, AI, Enemy, or a HTN controlled node. You should be using this to tell
## your agent how to complete [i]this[/i] task.[br][br]
##
## [param world_state]: This is a dictionary of the world state that has been altered
## by all previous tasks before this. Consider the world_state given here to be
## what the agent is/will act upon. You may alter the [param world_state] here as needed.
##
## [codeblock]
##  func run_operation(HTN_finished_op_callback: Callable, agent: Node, world_state: Dictionary) -> void:
##      # Set the current state to having the agent begin moving around the scene
##      world_state["is_travelling"] = true
##
##      # Call some `move_to` operation on the agent to pathfind from its current
##      # position to the "target" position according to the world_state
##      var nav_agent: NavigationAgent2D = agent.navigator.move_to(world_state["target"])
##
##      # Wait for the nav_agent to finish moving
##      await agent.operation_function.signal
##
##      # Let the HTN Planner know it's good to move on! :D
##      HTN_finished_op_callback.call()
## [/codeblock]
func run_operation(HTN_finished_op_callback: Callable, agent: Node, world_state: Dictionary) -> void:
	pass

## - Used to apply [b]Immediate[/b] effects to the [param world_state].[br]
## - Used [b][color=yellow]ONLY[/color][/b] in plan generation.[br]
## - Use this for a task that requires to wait but you still need to update the
## [param world_state].[br][br]
##
## [param world_state]: This is a dictionary of the [param world_state] that has been altered
## by all previous tasks before this. Consider the world_state given here to be
## what the agent is/will act upon. You may alter the [param world_state] here as needed.
## [br][br]
## [codeblock]
## func apply_effects(world_state: Dictionary) -> void:
##     world_state["is_travelling"] = false
##     world_state["current_position"] = world_state["target"]
## [/codeblock]
func apply_effects(world_state: Dictionary) -> void:
	pass
