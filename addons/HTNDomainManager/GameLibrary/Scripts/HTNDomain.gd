class_name HTNDomain
extends Resource

# [ (task_name (StringName))... ]
@export var required_primitives: Array[StringName] = []

# [ (domain_name (StringName))... ]
@export var required_domains: Array[StringName] = []

# {splitter_node_key (StringName) : { "method_branches": [(method_node_key: StringName)...] }}
@export var splits: Dictionary

# { method_node_key (StringName) : { "method_data": data (Dictionary), "task_chain": [(task_name: StringName)...]}}
@export var methods: Dictionary

# { effect_node_key (StringName) : { "world_state_key" : {"type_id": int, "value": any} } }
@export var effects: Dictionary
