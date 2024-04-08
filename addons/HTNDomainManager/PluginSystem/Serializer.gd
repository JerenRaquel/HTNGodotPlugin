@tool
class_name HTNSerializer
extends Control

const RESOURCE_PATH := "res://addons/HTNDomainManager/HTNGameLibrary/Data/Resources/"
const SCRIPT_PATH := "res://addons/HTNDomainManager/HTNGameLibrary/Data/Scripts/"
const DOMAIN_PATH := "res://addons/HTNDomainManager/HTNGameLibrary/Data/Domains/"
const SAVE_PATH := "res://addons/HTNDomainManager/HTNGameLibrary/Data/GraphSaves/"
const BLACK_LIST := ["task_name", "preconditions"]
#region Primitive Task Script Template
const FILE_TEMPLATE := "
extends HTNPrimitiveTask
# IMPORTANT: For more information on what these functions do, refer to the
# documentation by pressing F1 on your keyboard and searching
# for `HTNPrimitiveTask`. Happy scripting! :D

func run_operation(agent: Node, world_state: Dictionary) -> void:
	pass # Replace with function body

func apply_effects(world_state: Dictionary) -> void:
	pass # Replace with function body

func apply_expected_effects(world_state: Dictionary) -> void:
	pass # Replace with function body

"
#endregion

var _manager: HTNDomainManager

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager

func get_script_path_from_name(file_name: String) -> String:
	var script_file_path := SCRIPT_PATH + file_name + ".gd"
	if not FileAccess.file_exists(script_file_path):
		_manager.validation_handler.send_error_generic(
			"Can't locate path for file: " + file_name
		)
		return ""

	return script_file_path

func get_domain_path_from_name(file_name: String) -> String:
	var domain_file_path := DOMAIN_PATH + file_name + ".tres"
	if not FileAccess.file_exists(domain_file_path):
		_manager.validation_handler.send_error_generic(
			"Can't locate path for file: " + file_name
		)
		return ""

	return domain_file_path

func get_resource_path_from_name(file_name: String) -> String:
	var resource_file_path := RESOURCE_PATH + file_name + ".tres"
	if not FileAccess.file_exists(resource_file_path):
		_manager.validation_handler.send_error_generic(
			"Can't locate path for file: " + file_name
		)
		return ""

	return resource_file_path

func edit_script(file_name: String) -> void:
	var script_file_path := get_script_path_from_name(file_name)
	if script_file_path.is_empty(): return

	var script := load(script_file_path)
	EditorInterface.edit_script(script)
	EditorInterface.set_main_screen_editor("Script")

func get_script_export_data(file_name: String) -> Dictionary:
	var resource_file_path := get_resource_path_from_name(file_name)
	if resource_file_path.is_empty(): return {}

	var resource: HTNPrimitiveTask = ResourceLoader.load(resource_file_path)
	var data := {}
	var prop_list: Array[Dictionary] = resource.get_script().get_script_property_list()
	for prop: Dictionary in prop_list:
		if prop["usage"] != 4102: continue

		var prop_name: String = prop["name"]
		if prop_name.ends_with(".gd"): continue
		if prop_name in BLACK_LIST: continue

		if prop_name not in data:
			data[prop_name] = prop
			data[prop_name]["value"] = resource[prop_name]

	return data

func set_script_export_data(file_name: String, data: Array[Dictionary]) -> bool:
	var resource_file_path := get_resource_path_from_name(file_name)
	if resource_file_path.is_empty(): return false

	var resource := ResourceLoader.load(resource_file_path)
	for prop: Dictionary in data:
		resource[prop["name"]] = prop["value"]
	return true

func prettify_task_name(file_name: String) -> String:
	var result := file_name
	return convert_to_class_name(result.split(".")[0])

func convert_to_class_name(task_name: String) -> String:
	var tokens = task_name.capitalize().split(" ", false)
	var result := ""
	for token in tokens:
		result += token

	return result

func build_primitive_task(task_name: String) -> void:
	if task_name.is_empty() or task_name == "": return

	# TODO: Find out if task resource exists -- Need to find a way
	# But slapping HTN on everything should help

	var file_name: String = convert_to_class_name(task_name)
	var script: Script = _build_script(file_name)
	_build_resource(script, RESOURCE_PATH + file_name + ".tres")

func delete_primitive_task(task_name: String) -> bool:
	return _delete_files(
		task_name,
		"Script", SCRIPT_PATH + task_name + ".gd",
		"Resource", RESOURCE_PATH + task_name + ".tres"
	)

func delete_domain(domain_name: String) -> bool:
	return _delete_files(
		domain_name,
		"Graph Save", SAVE_PATH + domain_name + ".tres",
		"Domain", DOMAIN_PATH + domain_name + ".tres"
	)

func _delete_files(
		file_name: String,
		file_type1: String, file_path1: String,
		file_type2: String, file_path2: String) -> bool:
	var found_file1 := false
	var found_file2 := false
	if FileAccess.file_exists(file_path1):
		found_file1 = true
	if FileAccess.file_exists(file_path2):
		found_file2 = true

	if found_file1 and found_file2:
		DirAccess.remove_absolute(file_path1)
		DirAccess.remove_absolute(file_path2)
		return true
	else:
		var error_message: String = "Missing Files::"
		if not found_file1:
			error_message += file_type1 + " File"
		if not found_file1 and not found_file2:
			error_message += " and "
		if not found_file2:
			error_message += file_type2 + " File"
		push_error(error_message)
		return false



func _build_script(task_name: String) -> Script:
	var file_path := SCRIPT_PATH + task_name +".gd"
	var data: String = "class_name HTN" + task_name + FILE_TEMPLATE
	var write_data := data.split("\n")

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	for line in write_data:
		file.store_line(line)
	file.close()

	return load(file_path)

func _build_resource(script: Script, path: String) -> void:
	var resource_file: = Resource.new()
	resource_file.set_script(script)

	resource_file.resource_local_to_scene = true

	var result = ResourceSaver.save(resource_file, path)
	if result != OK: push_error("BUILDING RESOURCE FAILED::" + str(result))
