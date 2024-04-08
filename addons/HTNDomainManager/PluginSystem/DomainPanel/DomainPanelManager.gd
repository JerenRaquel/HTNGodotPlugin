@tool
class_name HTNDomainPanel
extends VBoxContainer

signal files_updated

const DOMAIN_LINE = preload("res://addons/HTNDomainManager/PluginSystem/DomainPanel/domain_line.tscn")

var _manager: HTNDomainManager
var _parent: VBoxContainer
var _domain_name_line_edit: LineEdit
var _quick_save_button: Button
var _domain_file_name: Label

func initialize(manager: HTNDomainManager, quick_save_button: Button, domain_file_name: Label) -> void:
	_manager = manager
	_parent = %Parent
	_domain_name_line_edit = %DomainNameLineEdit
	_domain_file_name = domain_file_name
	_domain_file_name.text = "No File Loaded"
	_quick_save_button = quick_save_button
	_quick_save_button.pressed.connect(_on_build_button_pressed)
	_quick_save_button.disabled = true
	_refresh()
	_filter("")

func get_availible_domains() -> Array[String]:
	var domain_names: Array[String] = []
	var file_names := DirAccess.get_files_at(_manager.serializer.DOMAIN_PATH)
	for file_name in file_names:
		var parsed_name := file_name.replace(".tres", "")
		if parsed_name not in domain_names:
			domain_names.push_back(parsed_name)

	return domain_names

func get_current_working_domain() -> String:
	if _domain_file_name.text == "No File Loaded": return ""	# Empty

	return _domain_file_name.text.replace("Domain Loaded: ", "")

func clear_graph() -> void:
	_domain_file_name.text = "No File Loaded"
	_domain_name_line_edit.clear()
	_quick_save_button.disabled = true

func _load_domain(domain_name: String) -> void:
	if not _manager.domain_builder.load_domain_file(domain_name): return

	_quick_save_button.disabled = false
	_domain_file_name.text = "Domain Loaded: " + domain_name
	_domain_name_line_edit.text = domain_name
	_manager.validation_handler.send_message(
		"Graph Loaded! Happy connecting! :D",
		_manager.validation_handler.MessageType.OK,
		true
	)
	_manager.not_saved = false

func _create_domain_line(file_name: String) -> void:
	var domain_line_instance := DOMAIN_LINE.instantiate()
	_parent.add_child(domain_line_instance)
	domain_line_instance.initialize(file_name, _on_load_pressed, _on_delete_pressed)

func _refresh() -> void:
	for child: HBoxContainer in _parent.get_children():
		child.queue_free()

	var file_names := DirAccess.get_files_at(_manager.serializer.DOMAIN_PATH)
	var found_loaded_file := false
	for file_name in file_names:
		if _domain_name_line_edit.text == file_name.replace(".tres", ""):
			found_loaded_file = true
		_create_domain_line(file_name)
	if not found_loaded_file:
		_domain_file_name.text = "No File Loaded"
		_quick_save_button.disabled = true
		_domain_name_line_edit.clear()

func _filter(filter: String) -> void:
	for child: HBoxContainer in _parent.get_children():
		if filter == "" or child.contains(filter):
			child.show()
		else:
			child.hide()

func _on_delete_pressed(instance: HBoxContainer, domain_name: String) -> void:
	_manager.warning_screen.open(
		"You are about to delete this domain file: " + domain_name +\
		"\nAre you sure?",
		(func() -> void:
			if _manager.serializer.delete_domain(domain_name):
				instance.queue_free()
				_refresh()
				files_updated.emit()
			),
		Callable()
	)

func _on_load_pressed(domain_name: String) -> void:
	if domain_name.is_empty():
		_manager.validation_handler.send_message(
			_manager.validation_handler.INVALID_DOMAIN_NAME,
			_manager.validation_handler.MessageType.ERROR
		)
		return

	if _manager.not_saved:
		_manager.warning_screen.open(
			"You are about overwrite a domain with unsaved changes.\nAre you sure?",
			func(): _load_domain(domain_name),
			Callable()
		)
	else:
		_load_domain(domain_name)

func _on_refresh_button_pressed() -> void:
	_refresh()

func _on_search_bar_text_changed(new_text: String) -> void:
	_filter(new_text)

func _on_build_button_pressed() -> void:
	if _domain_name_line_edit.text.is_empty():
		_manager.validation_handler.send_message(
			_manager.validation_handler.INVALID_DOMAIN_NAME,
			_manager.validation_handler.MessageType.ERROR
		)
		_quick_save_button.disabled = true
		return

	if not _manager.validation_handler.validate_graph(_domain_name_line_edit.text):
		_quick_save_button.disabled = true
		return

	_quick_save_button.disabled = false
	_manager.validation_handler.send_message(
		"Build Complete! Graph Saved! :D",
		_manager.validation_handler.MessageType.OK,
		true
	)
	_manager.not_saved = false
	_refresh()
	files_updated.emit()
	_domain_file_name.text = "Domain Loaded: " + _domain_name_line_edit.text

func _on_domain_name_line_edit_text_changed(new_text: String) -> void:
	_quick_save_button.disabled = true
