@tool
class_name HTNDomainManager
extends Control

signal graph_tool_bar_toggled(state: bool)
signal graph_tab_changed
signal task_created
signal task_deleted
signal node_name_altered
signal domains_updated

# Toolbar
@onready var task_panel_button: Button = %TaskPanelButton
@onready var goto_panel_button: Button = %GotoPanelButton
@onready var graph_tools_toggle: CheckButton = %GraphToolsToggle
@onready var clear_graph_button: Button = %ClearGraphButton
@onready var build_domain_button: Button = %BuildDomainButton
@onready var domain_panel_button: Button = %DomainPanelButton
# Containers
@onready var tab_container: HTNTabGraphManager = %TabContainer
@onready var task_panel: HTNTaskPanelManager = %TaskPanel
@onready var goto_panel: HTNGoToManager = %GotoPanel
@onready var domain_panel: HTNDomainPanel = %DomainPanel
# Managers
@onready var file_manager: HTNFileManager = %FileManager
@onready var notification_handler: HTNNotificaionHandler = %NotificationHandler
@onready var domain_saver: HTNDomainSaver = %DomainSaver
@onready var warning_box: HTNWarningBox = %WarningBox
# Other
@onready var condition_editor: HTNConditionEditor = %ConditionEditor
@onready var effect_editor: HTNEffectEditor = %EffectEditor
@onready var left_v_separator: VSeparator = %LeftVSeparator
@onready var right_v_separator: VSeparator = %RightVSeparator

var current_graph: HTNDomainGraph = null:
	set(value):
		current_graph = value
		_update_toolbar_buttons()

func _ready() -> void:
	graph_tools_toggle.toggled.connect(
		func(state: bool) -> void: graph_tool_bar_toggled.emit(state)
	)
	HTNGlobals.graph_altered.connect(_update_toolbar_buttons)
	domains_updated.connect(_update_domain_button)
	left_v_separator.hide()
	right_v_separator.hide()

	tab_container.initialize(self)
	file_manager.initialize(self)
	condition_editor.initialize(self)
	effect_editor.initialize(self)
	task_panel.initialize(self)
	goto_panel.initialize(self)
	domain_panel.initialize(self)
	warning_box.initialize(self)
	notification_handler.initialize()

	_update_toolbar_buttons()
	_update_domain_button()

func load_domain(domain_name: String) -> void:
	%DomainLoader.load_domain(domain_name)
	_update_toolbar_buttons()

func _update_toolbar_buttons() -> void:
	if current_graph == null:
		graph_tools_toggle.disabled = true
		build_domain_button.disabled = true
		goto_panel_button.disabled = true
		clear_graph_button.disabled = true
		goto_panel_button.set_pressed_no_signal(false)
		goto_panel.hide()
	else:
		graph_tools_toggle.disabled = false
		if current_graph.is_saved:
			build_domain_button.disabled = true
		else:
			build_domain_button.disabled = false

		if current_graph.nodes.size() <= 1:
			clear_graph_button.disabled = true
		else:
			clear_graph_button.disabled = false
		goto_panel_button.disabled = false

func _update_domain_button() -> void:
	if file_manager.check_if_no_domains():
		domain_panel_button.disabled = true
	else:
		domain_panel_button.disabled = false

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

func _on_domain_panel_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		right_v_separator.show()
		domain_panel.show()
	else:
		domain_panel.hide()
		right_v_separator.hide()

func _on_clear_graph_button_pressed() -> void:
	if not current_graph: return
	warning_box.open(
		"You are about to remove nodes for this graph.\nContinue?",
		current_graph.clear,
		Callable()
	)

func _on_build_domain_button_pressed() -> void:
	build_domain_button.disabled = true
	if not current_graph.validator.validate(): return
	if not domain_saver.save(current_graph): return

	notification_handler.send_message("Build Complete! Graph Saved!")
	current_graph.is_saved = true
	domain_panel._refresh()
	domains_updated.emit()
