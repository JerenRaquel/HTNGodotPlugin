@tool
class_name HTNDomainNode
extends HTNBaseNode

const EMPTY_DOMAIN_NAME = "N/A"
const NO_DOMAINS_TO_LINK := "WARNING:There are no domains to link to.\nConsider making one or deleting this node."
const SELF_LINK := """WARNING: You've selected the same domain as the currently being edited domain.
Assuming all build rules are satisfied, when running the currently being edited domain within the HTN Planner Scene Node,
it may cause an infinite loop while planning or running the plan due to an infinite recursion.
TLDR: This may cause a stack overflow due to recursion."""

@onready var warning_symbol: TextureRect = %WarningSymbol
@onready var domain_option_button: OptionButton = %DomainOptionButton

func initialize(manager: HTNDomainManager) -> void:
	super(manager)
	warning_symbol.hide()
	_manager.domain_created.connect(_refresh)
	_manager.domain_deleted.connect(_refresh)
	_refresh()

func get_node_name() -> String:
	if domain_option_button.item_count == 0: return ""

	var domain_name: String = domain_option_button.get_item_text(domain_option_button.selected)
	if domain_name == EMPTY_DOMAIN_NAME: return ""

	return domain_name

# Return value:
#	On valid: return "" (and empty string)
#	On invalid: return an error message string
func validate_self() -> String:
	if get_node_name().is_empty():
		return "Node created with no domains to link to..."
	return ""

func load_data(data) -> void:
	pass

func _refresh() -> void:
	var domain_names: Array = _manager.file_manager.get_all_domain_names()
	if domain_names.is_empty():
		warning_symbol.tooltip_text = NO_DOMAINS_TO_LINK
		warning_symbol.show()
		return

	domain_names.sort()

	# Parse the currently selected task name
	var last_item: String
	if domain_option_button.item_count == 1:
		last_item = domain_option_button.get_item_text(0)
		if last_item == EMPTY_DOMAIN_NAME:
			last_item = ""
	elif domain_option_button.item_count > 1:
		last_item = domain_option_button.get_item_text(domain_option_button.selected)

	domain_option_button.clear()

	# Add all the task names
	var idx := 0
	for domain_name: String in domain_names:
		domain_option_button.add_item(domain_name)
		if not last_item.is_empty() and domain_name == last_item:
			domain_option_button.select(idx)
			_on_domain_option_button_item_selected(idx)
		idx += 1
	if last_item.is_empty():
		domain_option_button.select(0)
		_on_domain_option_button_item_selected(0)

func _on_domain_option_button_item_selected(index: int) -> void:
	# No Domains Selected
	if get_node_name().is_empty(): return

	# Check if domain links to itself
	if _manager.file_manager.check_if_domain_links(_manager.current_graph.domain_name, get_node_name()):
		warning_symbol.tooltip_text = SELF_LINK
		warning_symbol.show()
	else:
		warning_symbol.hide()