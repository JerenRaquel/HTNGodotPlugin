@tool
class_name HTNDomainLine
extends HBoxContainer

@onready var domain_button: Button = %DomainButton

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager, domain_name: String) -> void:
	_manager = manager
	domain_button.text = domain_name

func _on_delete_button_pressed() -> void:
	# CRITICAL: Add a "are you sure"

	_manager.file_manager.delete_domain(domain_button.text)
