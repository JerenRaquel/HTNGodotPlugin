@tool
class_name HTNDomainPanel
extends VBoxContainer

const DOMAIN_LINE = preload("res://addons/HTNDomainManager/PluginSystem/DomainPanel/DomainLine/domain_line.tscn")

@onready var domain_name_line_edit: LineEdit = %DomainNameLineEdit
@onready var searchbar: LineEdit = %Searchbar
@onready var domain_container: VBoxContainer = %DomainContainer

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	hide()
	_manager = manager
	_refresh()

func _refresh() -> void:
	# Clear the old set
	for child: HTNDomainLine in domain_container.get_children():
		if child.is_queued_for_deletion(): continue
		child.queue_free()

	searchbar.editable = false

	var domain_names: Array = _manager.file_manager.get_all_domain_names()
	if domain_names.is_empty(): return

	domain_names.sort()

	for domain_name: String in domain_names:
		var domain_line_instance := DOMAIN_LINE.instantiate()
		domain_container.add_child(domain_line_instance)
		domain_line_instance.initialize(_manager)
	searchbar.editable = true

func _on_build_button_pressed() -> void:
	pass # Replace with function body.
