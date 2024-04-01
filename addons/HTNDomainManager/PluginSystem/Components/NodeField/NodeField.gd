@tool
class_name HTNNodeField
extends HBoxContainer

var _type: int = -1
var _name: Label
var _value
var _unsuppored_value

func set_data(var_name: String, data: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	_name = null
	_value = null
	_type = -1
	_unsuppored_value = null

	_name = Label.new()
	_name.text = var_name
	add_child(_name)

	_type = data["type"]
	match _type:
		1:	# Bool
			_value = CheckButton.new()
			_value.button_pressed = data["value"]
		2:	# Int
			_value = SpinBox.new()
			_value.step = 1
			_value.allow_greater = true
			_value.allow_lesser = true
			_value.value = int(data["value"])
		3:	# Float
			_value = SpinBox.new()
			_value.step = 1.0
			_value.allow_greater = true
			_value.allow_lesser = true
			_value.value = float(data["value"])
		4:	# String
			_value = LineEdit.new()
			_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_value.value = data["value"]
		_:	# Unsupported
			_unsuppored_value = data["value"]
			_value = Label.new()
			_value.text = "Unsupported Data Type"
			_value.tooltip_text =\
			"Sorry! I currently don't support this data type as of this version.\
			Please use the filesystem to edit the property value in the inspector."

	_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_value)

func get_data() -> Dictionary:
	var val
	match _type:
		1:	# Bool
			val = (_value as CheckButton).button_pressed
		2, 3:	# Int, Float
			val = (_value as SpinBox).value
		4:	# String
			val = (_value as LineEdit).text
		_:	# Unsupported
			val = _unsuppored_value

	return {
		"name": _name.text,
		"value": val
	}
