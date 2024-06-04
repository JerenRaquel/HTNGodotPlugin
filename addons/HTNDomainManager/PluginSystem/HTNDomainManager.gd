@tool
class_name HTNDomainManager
extends Control

signal graph_tool_bar_toggled(state: bool)

# Toolbar
@onready var graph_tools_toggle: CheckButton = %GraphToolsToggle
# Containers
@onready var tab_container: TabGraphManager = %TabContainer
# Other
@onready var node_spawn_menu: HTNNodeSpawnMenu = %NodeSpawnMenu

var current_graph: HTNDomainGraph = null

func _ready() -> void:
	graph_tools_toggle.toggled.connect(
		func(state: bool) -> void: graph_tool_bar_toggled.emit(state)
	)
	tab_container.initialize(self)
	node_spawn_menu.initialize(self)
