@tool
class_name SimulationManager
extends VBoxContainer

const EFFECT_LINE = preload("res://addons/HTNDomainManager/PluginSystem/SimulationPanel/sim_line.tscn")

var _manager: HTNDomainManager
var _states_parent: VBoxContainer

func initialize(manager: HTNDomainManager) -> void:
	_manager = manager
	_states_parent = %States
	_update_visiable_states("")

func _update_visiable_states(filter: String) -> void:
	var search_key := filter.to_lower()
	for sim_line: HBoxContainer in _states_parent.get_children():
		var sim_line_key: String = sim_line._world_state_key.to_lower()
		if filter == "" or sim_line_key.contains(search_key):
			sim_line.show()
		else:
			sim_line.hide()

func _on_add_state_button_pressed() -> void:
	var effect_line_instance := EFFECT_LINE.instantiate()
	_states_parent.add_child(effect_line_instance)
	effect_line_instance.initialize()

func _on_search_bar_text_changed(new_text: String) -> void:
	_update_visiable_states(new_text)
