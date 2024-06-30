@tool
extends Node

signal graph_altered
signal graph_tab_changed
signal current_graph_changed
signal task_created
signal task_deleted
signal graph_tool_bar_toggled(button_state: bool)
signal node_name_altered
signal domains_updated

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

var file_manager: HTNFileManager
var warning_box: HTNWarningBox
var effect_editor: HTNEffectEditor
var condition_editor: HTNConditionEditor
var notification_handler: HTNNotificaionHandler
var connection_handler: HTNConnectionHandler
var validator: HTNGraphValidator
var current_graph: HTNDomainGraph = null:
	set(value):
		current_graph = value
		current_graph_changed.emit()

func get_packed_node_as_flat(node_type: String) -> PackedScene:
	if node_type == "Root": return NODES["Root"]

	for category: String in NODES.keys():
		if category == "Root": continue
		for type: String in NODES[category].keys():
			if type == node_type:
				return NODES[category][type]

	return null
