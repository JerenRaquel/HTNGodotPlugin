@tool
class_name HTNFileManager
extends Node

const HTN_REFERENCE_FILE_PATH := "res://addons/HTNDomainManager/Data/HTNReferenceFile.tres"
const TASK_PATH := "res://addons/HTNDomainManager/Data/Tasks/"
const SCRIPT_PATH := "res://addons/HTNDomainManager/Data/Scripts/"
const DOMAIN_PATH := "res://addons/HTNDomainManager/Data/Domains/"
#region Task Script Template
const FILE_TEMPLATE := "extends HTNTask
# IMPORTANT: For more information on what these functions do, refer to the
# documentation by pressing F1 on your keyboard and searching
# for HTNTask`. Happy scripting! :D

func run_operation(HTN_finished_op_callback: Callable, agent: Node, world_state: Dictionary) -> void:
	pass # Replace with function body

func apply_effects(world_state: Dictionary) -> void:
	pass # Replace with function body

func apply_expected_effects(world_state: Dictionary) -> void:
	pass # Replace with function body"
#endregion

static func check_if_valid_name(task_name: String) -> bool:
	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	if task_name in HTN_reference_file["tasks"]:
		return false
	return true

static func check_if_domain_name_exists(domain_name: String) -> HTNDomain:
	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	return HTN_reference_file["domains"].get(domain_name, null)

static func check_if_no_domains() -> bool:
	return DirAccess.get_files_at(DOMAIN_PATH).is_empty()

# NOTE: Time Complexity: O(N) where N is every domain linked
# Utilizes DFS for searching
static func check_if_domain_links_to_self(original_domain_name: String, domain_name_link: String) -> bool:
	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	# Lazy Checks
	# - Check if domain exists
	if original_domain_name not in HTN_reference_file["domains"]: return false
	# - Check if same
	if original_domain_name == domain_name_link: return true
	# - Check if there's no domains to check
	if HTN_reference_file["domains"].is_empty(): return false
	# - Check if the linking domain has any domains within
	var domain_names: Array = HTN_reference_file["domains"][domain_name_link]["domain_map"].values()
	if domain_names.is_empty(): return false
	# - Check if original domain is within this linking domain
	if original_domain_name in domain_names: return true

	# DFS Search
	var closed_set: Array[StringName] = [original_domain_name]
	for cur_domain_name: StringName in domain_names:
		# Check if current domain name has any domains linked
		var sub_domain_list: Array = HTN_reference_file["domains"][cur_domain_name]["domain_map"].values()
		if sub_domain_list.is_empty():
			if cur_domain_name not in closed_set:
				closed_set.push_back(cur_domain_name)
			continue

		# Dig deeper
		if _check_if_domain_links_helper(HTN_reference_file, closed_set, cur_domain_name, original_domain_name):
			return true
		# Found nothing
		if cur_domain_name not in closed_set:
			closed_set.push_back(cur_domain_name)

	# Does not link at any time
	return false

static func _check_if_domain_links_helper(HTN_reference_file: HTNReferenceFile,
			closed_set: Array[StringName], current_domain_name: String, original_domain_name: String) -> bool:
	for cur_domain_name: StringName in HTN_reference_file["domains"][current_domain_name]["domain_map"].values():
		# Already Searched
		if cur_domain_name in closed_set: continue

		# Check if sub domain name is the same as the original root domain
		if cur_domain_name == original_domain_name: return true

		# Check if current domain name has any domains linked
		var sub_domain_list: Array = HTN_reference_file["domains"][cur_domain_name]["domain_map"].values()
		if sub_domain_list.is_empty():
			if cur_domain_name not in closed_set:
				closed_set.push_back(cur_domain_name)
			continue

		# Dig deeper
		if _check_if_domain_links_helper(HTN_reference_file, closed_set, cur_domain_name, original_domain_name):
			return true
		# Found nothing
		if cur_domain_name not in closed_set:
			closed_set.push_back(cur_domain_name)

	# Does not link at any time
	return false

static func get_all_task_names() -> Array:
	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	return HTN_reference_file["tasks"].keys()

static func get_all_domain_names() -> Array:
	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	return HTN_reference_file["domains"].keys()

static func get_awaiting_task_state(task_name: String) -> bool:
	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	return HTN_reference_file["tasks"][task_name]["requires_awaiting"]

static func toggle_awaiting_task_state(task_name: String, state: bool) -> void:
	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	HTN_reference_file["tasks"][task_name]["requires_awaiting"] = state
	if ResourceSaver.save(HTN_reference_file, HTN_REFERENCE_FILE_PATH) != OK:
		push_error("Awaiting state was not able to be updated...")

static func create_task(task_name: String) -> bool:
	if task_name.is_empty(): return false

	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	if task_name in HTN_reference_file["tasks"]: return false

	var file_name: String = task_name.to_pascal_case()
	var script_path := SCRIPT_PATH + task_name +".gd"
	var script: Script = _build_script(file_name, script_path)
	if script == null: return false

	var task_resource: HTNTask = _build_resource(script, file_name)
	if task_resource == null:
		DirAccess.remove_absolute(script_path)
		return false

	HTN_reference_file["scripts"][task_name] = script_path
	HTN_reference_file["tasks"][task_name] = task_resource
	return ResourceSaver.save(HTN_reference_file, HTN_REFERENCE_FILE_PATH) == OK

static func edit_script(task_name: String) -> void:
	if task_name.is_empty(): return

	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	if task_name not in HTN_reference_file["scripts"]: return

	var script := load(HTN_reference_file["scripts"][task_name])
	EditorInterface.edit_script(script)
	EditorInterface.set_main_screen_editor("Script")

static func delete_task(task_name: String) -> bool:
	if task_name.is_empty(): return false

	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	var script_path:String = HTN_reference_file["scripts"][task_name]
	var delete_state := _delete_files(
		"Script", script_path,
		"Task Resource File", TASK_PATH + task_name + ".tres"
	)
	if delete_state:
		HTN_reference_file["scripts"].erase(task_name)
		HTN_reference_file["tasks"].erase(task_name)
	if ResourceSaver.save(HTN_reference_file, HTN_REFERENCE_FILE_PATH) != OK:
		return false
	return delete_state

static func delete_domain(domain_name: String) -> bool:
	if domain_name.is_empty(): return false

	var HTN_reference_file: HTNReferenceFile = ResourceLoader.load(HTN_REFERENCE_FILE_PATH)
	var graph_path: String = HTN_reference_file["graph_saves"][domain_name]
	var delete_state := _delete_files(
		"Graph Save", graph_path,
		"Domain", DOMAIN_PATH + domain_name + ".tres"
	)
	if delete_state:
		HTN_reference_file["graph_saves"].erase(domain_name)
		HTN_reference_file["domains"].erase(domain_name)
	if ResourceSaver.save(HTN_reference_file, HTN_REFERENCE_FILE_PATH) != OK:
		return false
	return delete_state

static func _delete_files(file_type1: String, file_path1: String, file_type2: String, file_path2: String) -> bool:
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
			push_error(file_path1)
		if not found_file1 and not found_file2:
			error_message += " and "
		if not found_file2:
			error_message += file_type2 + " File"
			push_error(file_path2)
		return false

static func _build_script(task_name: String, path: String) -> Script:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return null

	var data: String = FILE_TEMPLATE
	var write_data := data.split("\n")
	for line in write_data:
		file.store_line(line)
	file.close()

	return load(path)

static func _build_resource(script: Script, file_name: String) -> Resource:
	var path: String = TASK_PATH + file_name + ".tres"
	var resource_file: = Resource.new()
	resource_file.set_script(script)

	var result = ResourceSaver.save(resource_file, path)
	if result != OK:
		push_error("BUILDING RESOURCE FAILED::" + str(result))
		return null
	return resource_file
