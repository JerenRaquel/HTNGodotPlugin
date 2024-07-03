@tool
extends EditorPlugin

const HTN_DOMAIN_MANAGER = preload("res://addons/HTNDomainManager/PluginSystem/HTN_domain_manager.tscn")
const PLUGIN_NAME := "HTNDomainManager"
const HTN_DATABASE_SCRIPT := "res://addons/HTNDomainManager/GameLibrary/Scripts/HTNDatabase.gd"
const HTN_GLOBALS := "res://addons/HTNDomainManager/PluginSystem/HTNGlobals.gd"

var manager: Control

func _enter_tree() -> void:
	# If not running in editor mode, shut off the plugin
	# -- HTNDatabase autoload should be included by runtime
	if not Engine.is_editor_hint(): return

	if not _setup_data():
		push_error("Data Cache Could Not Be Made...\nPreventing Startup....")
		return

	if not ProjectSettings.get_setting("editor/export/convert_text_resources_to_binary"):
		ProjectSettings.set_setting("editor/export/convert_text_resources_to_binary", false)

	if not ProjectSettings.has_setting("autoload/HTNDatabase"):
		add_autoload_singleton("HTNDatabase", HTN_DATABASE_SCRIPT)
	if not ProjectSettings.has_setting("autoload/HTNGlobals"):
		add_autoload_singleton("HTNGlobals", HTN_GLOBALS)

	manager = HTN_DOMAIN_MANAGER.instantiate()
	print_rich(
		"""The HTNDomainManager Plugin has added the autoloads 'HTNDatabase' and 'HTNGlobals' for plugin use.
This is used for keeping track of files during editor and runtime use.
Please remove when uninstalling this plugin.
[color=yellow]WARNING: Use of this plugin disables converting resources to binary on export.[/color]
[color=green]Thank you for using this![/color] [rainbow freq=1.0 sat=0.8 val=0.8]:D[/rainbow]
"""
	)
	EditorInterface.get_editor_main_screen().add_child(manager)
	_make_visible(false)
	main_screen_changed.connect(
		func(screen_name: String):
			if screen_name == PLUGIN_NAME:
				manager.set_focus_mode(Control.FOCUS_CLICK)
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

func _setup_data() -> bool:
	print("Setting Up Data Cache...")
	# Create Base Data Folder
	if not _create_and_validate_folder("res://addons/HTNDomainManager/Data/"):
		return false

	# Create Sub Data Folders
	if not _create_and_validate_folder("res://addons/HTNDomainManager/Data/Domains/"):
		return false
	if not _create_and_validate_folder("res://addons/HTNDomainManager/Data/GraphSaves/"):
		return false
	if not _create_and_validate_folder("res://addons/HTNDomainManager/Data/Scripts/"):
		return false
	if not _create_and_validate_folder("res://addons/HTNDomainManager/Data/Tasks/"):
		return false

	print_rich("[color=green]Data Cache Setup Complete...[/color]")
	return true

func _create_and_validate_folder(path: String) -> bool:
	if DirAccess.dir_exists_absolute(path): return true

	return DirAccess.make_dir_absolute(path) == OK
