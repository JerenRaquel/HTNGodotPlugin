@tool
class_name HTNFileManager
extends Control

var HTN_REFERENCE_FILE = preload("res://addons/HTNDomainManager/Data/ReferenceFiles/HTNReferenceFile.tres")
const TASK_PATH := "res://addons/HTNDomainManager/Data/Tasks/"
const SCRIPT_PATH := "res://addons/HTNDomainManager/Data/Scripts/"
#region Task Script Template
const FILE_TEMPLATE := "
extends HTNTask
# IMPORTANT: For more information on what these functions do, refer to the
# documentation by pressing F1 on your keyboard and searching
# for HTNTask`. Happy scripting! :D

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

func check_if_valid_name(task_name: String) -> bool:
	if task_name in HTN_REFERENCE_FILE["tasks"]:
		return false
	return true

func check_if_domain_name_exists(domain_name: String) -> bool:
	return domain_name in HTN_REFERENCE_FILE["domains"]

# NOTE: Time Complexity: O(N) where N is every domain linked
# Utilizes DFS for searching
func check_if_domain_links(original_domain_name: String, domain_name_link: String) -> bool:
	# Lazy Checks
	# - Check if domain exists
	if original_domain_name not in HTN_REFERENCE_FILE["domains"]: return false
	# - Check if same
	if original_domain_name == domain_name_link: return true
	# - Check if there's no domains to check
	if HTN_REFERENCE_FILE["domains"].is_empty(): return false
	# - Check if current domain name has any domains linked
	var domain_names: Array[StringName] = HTN_REFERENCE_FILE["domains"][original_domain_name]["required_domains"]
	if domain_names.is_empty(): return false

	# DFS Search
	var closed_set: Array[StringName] = [original_domain_name]
	for cur_domain_name: StringName in domain_names:
		# Check if sub domain name is the same as the one wanting to link
		if cur_domain_name == domain_name_link: return true
		# Check if current domain name has any domains linked
		var sub_domain_list: Array[StringName] = HTN_REFERENCE_FILE["domains"][cur_domain_name]["required_domains"]
		if sub_domain_list.is_empty():
			if cur_domain_name not in closed_set:
				closed_set.push_back(cur_domain_name)
			continue

		# Dig deeper
		if _check_if_domain_links_helper(closed_set, cur_domain_name, domain_name_link): return true
		# Found nothing
		if cur_domain_name not in closed_set:
			closed_set.push_back(cur_domain_name)

	# Does not link at any time
	return false

func get_all_task_names() -> Array:
	return HTN_REFERENCE_FILE["tasks"].keys()

func get_all_domain_names() -> Array:
	return HTN_REFERENCE_FILE["domains"].keys()

func get_awaiting_task_state(task_name: String) -> bool:
	return HTN_REFERENCE_FILE["tasks"][task_name]["requires_awaiting"]

func toggle_awaiting_task_state(task_name: String, state: bool) -> void:
	HTN_REFERENCE_FILE["tasks"][task_name]["requires_awaiting"] = state

func create_task(task_name: String) -> bool:
	if task_name.is_empty(): return false
	if not check_if_valid_name(task_name): return false

	var file_name: String = task_name.to_pascal_case()
	var script_path := SCRIPT_PATH + task_name +".gd"
	var script: Script = _build_script(file_name, script_path)
	if script == null: return false

	var task_resource: HTNTask = _build_resource(script, file_name)
	if task_resource == null:
		DirAccess.remove_absolute(script_path)
		return false

	HTN_REFERENCE_FILE["scripts"][task_name] = script_path
	HTN_REFERENCE_FILE["tasks"][task_name] = task_resource
	return true

func edit_script(task_name: String) -> void:
	if task_name.is_empty(): return
	if task_name not in HTN_REFERENCE_FILE["scripts"]: return

	var script := load(HTN_REFERENCE_FILE["scripts"][task_name])
	EditorInterface.edit_script(script)
	EditorInterface.set_main_screen_editor("Script")

func delete_task(task_name: String) -> bool:
	if task_name.is_empty(): return false

	var script_path:String = HTN_REFERENCE_FILE["scripts"][task_name]
	var task_resource: Resource = HTN_REFERENCE_FILE["tasks"][task_name]
	var delete_state := _delete_files(
		"Script", script_path,
		"Task Resource File", task_resource.resource_path
	)
	if delete_state:
		HTN_REFERENCE_FILE["scripts"].erase(task_name)
		HTN_REFERENCE_FILE["tasks"].erase(task_name)
	return delete_state

func delete_domain(domain_name: String) -> bool:
	if domain_name.is_empty(): return false

	var graph_path: String = HTN_REFERENCE_FILE["graph_saves"][domain_name]
	var domain_resource: Resource = HTN_REFERENCE_FILE["domains"][domain_name]
	var delete_state := _delete_files(
		"Graph Save", graph_path,
		"Domain", domain_resource.resource_path
	)
	if delete_state:
		HTN_REFERENCE_FILE["graph_saves"].erase(domain_name)
		HTN_REFERENCE_FILE["domains"].erase(domain_name)
	return delete_state

func _check_if_domain_links_helper(closed_set: Array[StringName], current_domain_name: String,
		domain_name_link: String) -> bool:
	for cur_domain_name: StringName in HTN_REFERENCE_FILE["domains"][current_domain_name]["required_domains"]:
		# Already Searched
		if cur_domain_name in closed_set: continue

		# Check if sub domain name is the same as the one wanting to link
		if cur_domain_name == domain_name_link: return true

		# Check if current domain name has any domains linked
		var sub_domain_list: Array[StringName] = HTN_REFERENCE_FILE["domains"][cur_domain_name]["required_domains"]
		if sub_domain_list.is_empty():
			if cur_domain_name not in closed_set:
				closed_set.push_back(cur_domain_name)
			continue

		# Dig deeper
		if _check_if_domain_links_helper(closed_set, cur_domain_name, domain_name_link): return true
		# Found nothing
		if cur_domain_name not in closed_set:
			closed_set.push_back(cur_domain_name)

	# Does not link at any time
	return false

func _delete_files(file_type1: String, file_path1: String, file_type2: String, file_path2: String) -> bool:
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

func _build_script(task_name: String, path: String) -> Script:
	var data: String = "class_name HTN" + task_name + FILE_TEMPLATE
	var write_data := data.split("\n")

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return null

	for line in write_data:
		file.store_line(line)
	file.close()

	return load(path)

func _build_resource(script: Script, file_name: String) -> Resource:
	var path: String = TASK_PATH + file_name + ".tres"
	var resource_file: = Resource.new()
	resource_file.set_script(script)

	var result = ResourceSaver.save(resource_file, path)
	if result != OK:
		push_error("BUILDING RESOURCE FAILED::" + str(result))
		return null
	return resource_file
