@tool
extends Node

signal graph_altered

const NODES: Dictionary = {
	"Root": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/RootNode/htn_root_node.tscn"),
	"Actions": {
		"Task": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/TaskNode/htn_task_node.tscn"),
		"Domain": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/DomainNode/htn_domain_node.tscn"),
	},
	"Manipulators": {
		"Applicator": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/ApplicatorNode/htn_applicator_node.tscn"),
	},
	"Methods": {
		"Always True Method": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/MethodNode/AlwaysTrue/htn_always_true_method_node.tscn"),
		"Method": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/MethodNode/Original/htn_method_node.tscn"),
	},
	"Misc": {
		"Splitter": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/SplitterNode/htn_splitter_node.tscn"),
		"Comment": preload("res://addons/HTNDomainManager/PluginSystem/Nodes/CommentNode/htn_comment_node.tscn"),
	}
}

func get_packed_node_as_flat(node_type: String) -> PackedScene:
	if node_type == "Root": return NODES["Root"]

	for category: String in NODES.keys():
		if category == "Root": continue
		for type: String in NODES[category].keys():
			if type == node_type:
				return NODES[category][type]

	return null
