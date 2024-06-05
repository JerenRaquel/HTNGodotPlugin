@tool
class_name HTNDomainManager
extends Control

signal graph_tool_bar_toggled(state: bool)
signal graph_altered
signal graph_tab_changed
signal task_created
signal task_deleted
signal node_name_altered

# Toolbar
@onready var task_panel_button: Button = %TaskPanelButton
@onready var goto_panel_button: Button = %GotoPanelButton
@onready var graph_tools_toggle: CheckButton = %GraphToolsToggle
# Containers
@onready var tab_container: HTNTabGraphManager = %TabContainer
@onready var task_panel: HTNTaskPanelManager = %TaskPanel
@onready var goto_panel: HTNGoToManager = %GotoPanel
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
	goto_panel.initialize(self)

func _on_task_panel_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		task_panel.show()
		left_v_separator.show()
		goto_panel_button.set_pressed_no_signal(false)
		goto_panel.hide()
	else:
		task_panel.hide()
		left_v_separator.hide()

func _on_goto_panel_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		goto_panel.show()
		left_v_separator.show()
		task_panel_button.set_pressed_no_signal(false)
		task_panel.hide()
	else:
		goto_panel.hide()
		left_v_separator.hide()

func _on_clear_graph_button_pressed() -> void:
	if not current_graph: return
	current_graph.clear()
