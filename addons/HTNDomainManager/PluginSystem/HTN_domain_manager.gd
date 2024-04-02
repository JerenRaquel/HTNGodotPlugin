@tool
extends EditorPlugin

const HTN_DOMAIN_MANAGER = preload("res://addons/HTNDomainManager/PluginSystem/HTN_domain_manager.tscn")
const PLUGIN_NAME := "HTNDomainManager"

var manager: Control

func _enter_tree() -> void:
	manager = HTN_DOMAIN_MANAGER.instantiate()
	EditorInterface.get_editor_main_screen().add_child(manager)
	_make_visible(false)
	manager.visibility_changed.connect(
		func() -> void:
			if manager.visible:
				manager.is_enabled = true
			else:
				manager.is_enabled = false
	)
	main_screen_changed.connect(
		func(screen_name: String):
			if screen_name == PLUGIN_NAME:
				manager.grab_focus()
	)

func _exit_tree() -> void:
	if manager:
		manager.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if manager:
		manager.visible = visible

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_base_control().get_theme_icon("GraphEdit", "EditorIcons")
