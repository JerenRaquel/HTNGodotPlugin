@tool
extends Panel

@onready var warning_text: Label = %WarningText

var _on_accept: Callable
var _on_decline: Callable

func initialize() -> void:
	hide()

func open(message: String, on_accept: Callable, on_decline: Callable) -> void:
	warning_text.text = message
	_on_accept = on_accept
	_on_decline = on_decline
	show()

func _close() -> void:
	warning_text.text = ""
	hide()

func _on_accept_pressed() -> void:
	if _on_accept.is_valid():
		_on_accept.call()
	hide()

func _on_decline_pressed() -> void:
	if _on_decline.is_valid():
		_on_decline.call()
	hide()
