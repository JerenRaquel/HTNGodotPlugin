@tool
extends HBoxContainer

@onready var load_button: Button = %LoadButton

var _loader: Callable
var _deleter: Callable

func initialize(file_name: String, loader_function: Callable, deleter_function: Callable) -> void:
	_loader = loader_function
	_deleter = deleter_function
	load_button.text = file_name.replace(".tres", "")

func contains(what: String) -> bool:
	var search_filter := what.to_lower()
	var self_filter := load_button.text.to_lower()
	return self_filter.contains(search_filter)

func _on_delete_button_pressed() -> void:
	_deleter.call(self, load_button.text)

func _on_load_button_pressed() -> void:
	_loader.call(load_button.text)
