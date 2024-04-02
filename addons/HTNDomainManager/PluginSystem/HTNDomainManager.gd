@tool
class_name HTNDomainManager
extends Control

enum LeftPanel { NONE, TASK, GOTO, SIM }

@onready var graph_handler: HTNGraphHandler = $GraphHandler
@onready var condition_editor: HTNConditionEditor = %ConditionEditor
@onready var effect_editor: HTNEffectEditor = %EffectEditor
@onready var side_panel_container: PanelContainer = %SidePanelContainer
@onready var task_list_button: Button = %TaskList
@onready var simulator_button: Button = %Simulator
@onready var simulation_panel: SimulationManager = %SimulationPanel
@onready var build_notice: Label = %BuildNotice
@onready var task_panel: HTNTaskPanelManager = %TaskPanel
@onready var serializer: HTNSerializer = $Serializer
@onready var validation_handler: HTNNodeValidationHandler = $ValidationHandler
@onready var domain_builder: HTNDomainBuilder = $DomainBuilder
@onready var warning_screen: Panel = $WarningScreen
@onready var goto_panel: HTNGotoManager = %GotoPanel
@onready var goto_panel_button: Button = %GotoPanelButton

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

	validation_handler.send_message("", validation_handler.MessageType.DEFAULT)
	side_panel_container.visible = (task_list_button.button_pressed or simulator_button.button_pressed)
	task_panel.visible = task_list_button.button_pressed
	simulation_panel.visible = simulator_button.button_pressed

	graph_handler.graph_altered.connect(
		func():
			validation_handler.send_message("Unsaved Changes", validation_handler.MessageType.WARNING)
			not_saved = true
	)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint(): return
	if not is_enabled or condition_editor.visible: return

	graph_handler.update()

func _load_domain() -> void:
	if not domain_builder.load_domain_file(domain_name): return
	validation_handler.send_message(
		"Graph Loaded! Happy connecting! :D",
		validation_handler.MessageType.OK, true
	)
	not_saved = false

func _toggle_left_panel(panel_ID: LeftPanel) -> void:
	side_panel_container.hide()
	task_list_button.set_pressed_no_signal(false)
	simulator_button.set_pressed_no_signal(false)
	goto_panel_button.set_pressed_no_signal(false)
	task_panel.hide()
	simulation_panel.hide()
	goto_panel.hide()

	if panel_ID == LeftPanel.NONE:
		return

	side_panel_container.show()
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

func _on_build_pressed() -> void:
	if domain_name.is_empty():
		validation_handler.send_message(
			validation_handler.INVALID_DOMAIN_NAME,
			validation_handler.MessageType.ERROR
		)
		return

	if not validation_handler.validate_graph(domain_name): return

	validation_handler.send_message("Build Complete! Graph Saved! :D", validation_handler.MessageType.OK, true)
	not_saved = false

func _on_load_pressed() -> void:
	if domain_name.is_empty():
		validation_handler.send_message(
			validation_handler.INVALID_DOMAIN_NAME,
			validation_handler.MessageType.ERROR
		)
		return

	if not_saved:
		warning_screen.open(
			"You are about overwrite a domain with unsaved changes.\nAre you sure?",
			_load_domain,
			Callable()
		)
	else:
		_load_domain()

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
