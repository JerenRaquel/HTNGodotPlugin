class_name HTNDomain
extends Resource

# [ (task_key (StringName))... ]
@export var required_tasks: Array[StringName] = []

# [ (domain_key (StringName))... ]
@export var required_domains: Array[StringName] = []

# {splitter_node_key (StringName) : { "method_branches": [(method_node_key: StringName)...] }}
@export var splits: Dictionary

#	{
#		method_node_key (StringName) : {
#			"method_data" (WorldState => String): {
#				"CompareID": (int),
#				"RangeID": (int),
#				"SingleID": (int),
#				"Value": any,
#				"RangeInclusivity": [boolean, boolean]
#			}, "task_chain": [(task_name: StringName)...]
#		}
#	}
@export var methods: Dictionary

# { effect_node_key (StringName) : { "world_state_key" : {"type_id": int, "value": any} } }
@export var effects: Dictionary
