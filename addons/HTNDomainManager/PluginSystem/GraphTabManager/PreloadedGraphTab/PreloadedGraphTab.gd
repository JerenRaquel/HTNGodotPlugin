@tool
class_name HTNPreloadedGraphTab
extends HTNGraphTab

func load_data(domain_name: String) -> HTNDomainGraph:
	get_parent()._manager.graph_tool_bar_toggled.connect(
		func(state: bool) -> void:
			domain_graph.show_menu = state
	)
	domain_graph = %DomainGraph
	is_empty = false
	name = domain_name
	return domain_graph

func get_domain_name() -> String:
	return name.replace("*", "")
