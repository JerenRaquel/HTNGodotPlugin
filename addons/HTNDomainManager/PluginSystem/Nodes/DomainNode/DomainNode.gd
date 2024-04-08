@tool
class_name HTNDomainNode
extends HTNBaseNode

@onready var option_button: OptionButton = %OptionButton
@onready var warning_symbol: TextureRect = %WarningSymbol

var _selected_domain: String

func initialize(manager: HTNDomainManager) -> void:
	super(manager)
	_manager.domain_panel.files_updated.connect(_on_files_updated)
	_update_domain_list()
	_select_default()

func get_node_name() -> String:
	if _selected_domain.is_empty(): return ""
	return "Domain - " + _selected_domain

# Return value:
#	On valid: return "" (and empty string)
#	On invalid: return an error message string
func validate_self() -> String:
	return ""

func load_data(data) -> void:
	for idx: int in option_button.item_count:
		if option_button.get_item_text(idx) == data:
			option_button.select(idx)
			_selected_domain = data
			return
	_select_default()

func get_selected_domain_name() -> String:
	if _selected_domain.is_empty(): return ""
	return _selected_domain

func _select_default() -> void:
	if option_button.item_count == 0: return
	option_button.select(0)
	_selected_domain = option_button.get_item_text(0)
	var current_working_domain: String = _manager.domain_panel.get_current_working_domain()
	if _selected_domain == current_working_domain:
		warning_symbol.show()
	else:
		warning_symbol.hide()

func _update_domain_list() -> void:
	option_button.clear()
	var domain_names := _manager.domain_panel.get_availible_domains()
	if domain_names.size() == 0: return

	var idx := 0
	for domain_name in domain_names:
		option_button.add_item(domain_name, idx)
		idx += 1

func _on_files_updated() -> void:
	_update_domain_list()
	if _selected_domain.is_empty(): return

	for idx: int in option_button.item_count:
		if option_button.get_item_text(idx) == _selected_domain:
			option_button.select(idx)
			return

func _on_option_button_item_selected(index: int) -> void:
	var current_working_domain: String = _manager.domain_panel.get_current_working_domain()
	_selected_domain = option_button.get_item_text(index)
	if _selected_domain == current_working_domain:
		warning_symbol.show()
	else:
		warning_symbol.hide()
