@tool
class_name HTNDomainManager
extends Control

enum LeftPanel { NONE, TASK, GOTO, SIM }

# Modules
@onready var graph_handler: HTNGraphHandler = $GraphHandler
@onready var serializer: HTNSerializer = $Serializer
@onready var validation_handler: HTNNodeValidationHandler = $ValidationHandler
@onready var domain_builder: HTNDomainBuilder = $DomainBuilder
# Panels -- Pop ups
@onready var condition_editor: HTNConditionEditor = %ConditionEditor
@onready var effect_editor: HTNEffectEditor = %EffectEditor
@onready var warning_screen: Panel = $WarningScreen
# Panels -- Left
@onready var side_panel_container_left: PanelContainer = %SidePanelContainerLeft
@onready var task_list_button: Button = %TaskList
@onready var task_panel: HTNTaskPanelManager = %TaskPanel
@onready var simulator_button: Button = %Simulator
@onready var simulation_panel: SimulationManager = %SimulationPanel
@onready var goto_panel: HTNGotoManager = %GotoPanel
@onready var goto_panel_button: Button = %GotoPanelButton
# Panels -- Right
@onready var side_panel_container_right: PanelContainer = %SidePanelContainerRight
@onready var domain_panel: HTNDomainPanel = %DomainPanel
@onready var domain_quick_save: Button = %DomainQuickSave
@onready var domain_file_name: Label = %DomainFileName
# Other
@onready var build_notice: Label = %BuildNotice

var is_enabled := false
var not_saved := false
var domain_name: String

func _ready() -> void:
	if not Engine.is_editor_hint(): return

	warning_screen.initialize()
	graph_handler.initialize(self)
	serializer.initialize(self)
	task_panel.initialize(self)
	simulation_panel.initialize(self)
	goto_panel.initialize(self)
	validation_handler.initialize(self)
	domain_builder.initialize(self)
	domain_panel.initialize(self, domain_quick_save, domain_file_name)

	validation_handler.send_message("", validation_handler.MessageType.DEFAULT)
	side_panel_container_left.visible = false
	side_panel_container_right.visible = false

	graph_handler.graph_altered.connect(
		func():
			validation_handler.send_message("Unsaved Changes", validation_handler.MessageType.WARNING)
			not_saved = true
	)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint(): return
	if not is_enabled or condition_editor.visible: return

	graph_handler.update()

func _toggle_left_panel(panel_ID: LeftPanel) -> void:
	side_panel_container_left.hide()
	task_list_button.set_pressed_no_signal(false)
	simulator_button.set_pressed_no_signal(false)
	goto_panel_button.set_pressed_no_signal(false)
	task_panel.hide()
	simulation_panel.hide()
	goto_panel.hide()

	if panel_ID == LeftPanel.NONE:
		return

	side_panel_container_left.show()
	match panel_ID:
		LeftPanel.TASK:
			task_list_button.set_pressed_no_signal(true)
			task_panel.show()
		LeftPanel.SIM:
			simulator_button.set_pressed_no_signal(true)
			simulation_panel.show()
		LeftPanel.GOTO:
			goto_panel_button.set_pressed_no_signal(true)
			goto_panel.show()

func _on_task_list_toggled(toggled_on: bool) -> void:
	_toggle_left_panel(LeftPanel.TASK if toggled_on else LeftPanel.NONE)

func _on_simulator_toggled(toggled_on: bool) -> void:
	_toggle_left_panel(LeftPanel.SIM if toggled_on else LeftPanel.NONE)

func _on_goto_panel_button_toggled(toggled_on: bool) -> void:
	_toggle_left_panel(LeftPanel.GOTO if toggled_on else LeftPanel.NONE)

func _on_name_text_changed(new_text: String) -> void:
	domain_name = new_text
	if new_text.is_empty():
		graph_handler._root_node.title = "Root"
	else:
		graph_handler._root_node.title = "Root - " + new_text

func _on_domain_panel_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		side_panel_container_right.show()
	else:
		side_panel_container_right.hide()
