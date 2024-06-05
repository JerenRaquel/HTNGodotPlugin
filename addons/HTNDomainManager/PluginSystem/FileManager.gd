@tool
class_name HTNFileManager
extends Control

const SCRIPT_PATH := "res://addons/HTNDomainManager/Data/Scripts/"

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager

func edit_script(file_name: String) -> void:
	if file_name.is_empty(): return

	var script_file_path := get_script_path_from_name(file_name)
	if script_file_path.is_empty(): return

	var script := load(script_file_path)
	EditorInterface.edit_script(script)
	EditorInterface.set_main_screen_editor("Script")

func get_script_path_from_name(file_name: String) -> String:
	var script_file_path := SCRIPT_PATH + file_name + ".gd"
	if not FileAccess.file_exists(script_file_path):
		# CRITICAL: Send an error to the validator
		#_manager.validation_handler.send_error_generic(
			#"Can't locate path for file: " + file_name
		#)
		return ""

	return script_file_path
