@tool
class_name HTNDomainManager
extends Control

@onready var graph_handler: HTNGraphHandler = $GraphHandler
@onready var condition_editor: HTNConditionEditor = %ConditionEditor
@onready var effect_editor: EffectEditor = %EffectEditor
@onready var side_panel_container: PanelContainer = %SidePanelContainer
@onready var task_list_button: Button = %TaskList
@onready var simulator_button: Button = %Simulator
@onready var simulation_panel: VBoxContainer = %SimulationPanel
@onready var build_notice: Label = %BuildNotice
@onready var task_panel: HTNTaskPanelManager = %TaskPanel
@onready var serializer: HTNSerializer = $Serializer
@onready var validation_handler: HTNNodeValidationHandler = $ValidationHandler
@onready var domain_builder: HTNDomainBuilder = $DomainBuilder
@onready var warning_screen: Panel = $WarningScreen
@onready var goto_line_edit: LineEdit = %GotoLineEdit

var is_enabled := false
var not_saved := false
var editor_interface_ref: EditorPlugin
var domain_name: String

func _ready() -> void:
	if not Engine.is_editor_hint(): return

	warning_screen.initialize()
	graph_handler.initialize(self)
	serializer.initialize(self)
	task_panel.initialize(self)
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

func _on_build_pressed() -> void:
	if domain_name.is_empty() or domain_name == "":
		validation_handler.send_message(
			validation_handler.INVALID_DOMAIN_NAME,
			validation_handler.MessageType.ERROR
		)
		return

	# Validate that there are any connections....
	# I know who you are. I put this in for you... ._.
	if not validation_handler.validate_there_are_any_connections(domain_name): return

	if not validation_handler.validate_node_data(): return

	# Validate each node's rules (listed above function declaration)
	if not validation_handler.validate_node_connections(graph_handler): return

	# Save Primitive Node Data to File
	if not validation_handler.save_primitive_node_data(): return

	# Save graph to domain file
	if not domain_builder.write_domain_file(domain_name): return

	validation_handler.send_message("Build Complete! Graph Saved! :D", validation_handler.MessageType.OK, true)
	not_saved = false

func _on_load_pressed() -> void:
	if domain_name.is_empty() or domain_name == "":
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
	if toggled_on:
		simulator_button.button_pressed = false
		side_panel_container.show()
		task_panel.show()
		simulation_panel.hide()
	else:
		side_panel_container.hide()
		task_panel.hide()

func _on_simulator_toggled(toggled_on: bool) -> void:
	if toggled_on:
		task_list_button.button_pressed = false
		side_panel_container.show()
		simulation_panel.show()
		task_panel.hide()
	else:
		side_panel_container.hide()
		simulation_panel.hide()

func _on_name_text_changed(new_text: String) -> void:
	domain_name = new_text
	if new_text.is_empty() or new_text == "":
		graph_handler._root_node.title = "Root"
	else:
		graph_handler._root_node.title = "Root - " + new_text

func _on_goto_root_button_pressed() -> void:
	graph_handler.graph_edit.zoom = 1.0
	var center := graph_handler.graph_edit.size / 2
	graph_handler.graph_edit.scroll_offset =\
		(graph_handler._root_node.position_offset +\
		graph_handler._root_node.size * Vector2(0.5, 1.0) -\
		center) / graph_handler.graph_edit.zoom

func _on_goto_button_pressed() -> void:
	if goto_line_edit.text.is_empty() or goto_line_edit.text == "":
		validation_handler.send_message(
			validation_handler.EMPTY_FIELD,
			validation_handler.MessageType.ERROR,
			true
		)
		return

	var data: Dictionary = graph_handler.get_node_offset(goto_line_edit.text)
	if data.is_empty():
		validation_handler.send_error_message_fade(
			goto_line_edit.text,
			validation_handler.GOTO_FAILED
		)
		return

	graph_handler.graph_edit.zoom = 1.0
	var center := graph_handler.graph_edit.size / 2
	var offset: Vector2 = data["offset"] + data["size"] * Vector2(0.5, 1.0) - center
	graph_handler.graph_edit.scroll_offset = offset / graph_handler.graph_edit.zoom
