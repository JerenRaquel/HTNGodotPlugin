@tool
class_name HTNDomainManager
extends Control

signal graph_tool_bar_toggled(state: bool)
signal task_deleted

# Toolbar
@onready var graph_tools_toggle: CheckButton = %GraphToolsToggle
# Containers
@onready var tab_container: HTNTabGraphManager = %TabContainer
@onready var task_panel: HTNTaskPanelManager = %TaskPanel
# Managers
@onready var file_manager: HTNFileManager = %FileManager
# Other
@onready var node_spawn_menu: HTNNodeSpawnMenu = %NodeSpawnMenu
@onready var condition_editor: HTNConditionEditor = %ConditionEditor
@onready var effect_editor: HTNEffectEditor = %EffectEditor
@onready var left_v_separator: VSeparator = %LeftVSeparator

var current_graph: HTNDomainGraph = null

func _ready() -> void:
	graph_tools_toggle.toggled.connect(
		func(state: bool) -> void: graph_tool_bar_toggled.emit(state)
	)
	left_v_separator.hide()
	tab_container.initialize(self)
	file_manager.initialize(self)
	node_spawn_menu.initialize(self)
	condition_editor.initialize(self)
	effect_editor.initialize(self)
	task_panel.initialize(self)

func _on_task_panel_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		task_panel.show()
		left_v_separator.show()
	else:
		task_panel.hide()
		left_v_separator.hide()
