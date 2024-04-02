@tool
class_name HTNNodeField
extends HBoxContainer

@onready var var_name_label: Label = %VarName
@onready var boolean_parameter: CheckButton = %BooleanParameter
@onready var string_parameter: LineEdit = %StringParameter
@onready var vector_parameter: HBoxContainer = %VectorParameter
@onready var x_value: SpinBox = %XValue
@onready var y_value: SpinBox = %YValue
@onready var z_value: SpinBox = %ZValue
@onready var unsupported_parameter: Label = %UnsupportedParameter

var _var_name: String
var _type: int
var _unsupported_value

func set_data(var_name: String, data: Dictionary) -> void:
	_var_name = var_name
	var_name_label.text = var_name
	_type = data["type"]
	_delete_all_but(_type)
	match _type:
		TYPE_BOOL:
			boolean_parameter.button_pressed = data["value"]
		TYPE_INT:
			x_value.value = int(data["value"])
			x_value.step = 1
		TYPE_FLOAT:
			x_value.value = data["value"]
			x_value.step = 0.1
		TYPE_STRING:
			string_parameter.text = data["value"]
		TYPE_VECTOR2:
			x_value.value = data["value"].x
			x_value.step = 0.1
			y_value.value = data["value"].y
			y_value.step = 0.1
		TYPE_VECTOR3:
			x_value.value = data["value"].x
			x_value.step = 0.1
			y_value.value = data["value"].y
			y_value.step = 0.1
			z_value.value = data["value"].z
			z_value.step = 0.1
		_:	# Unsupported data type
			_unsupported_value = data["value"]

func get_data() -> Dictionary:
	var value
	match _type:
		TYPE_BOOL:
			value = boolean_parameter.button_pressed
		TYPE_INT:
			value = x_value.value
		TYPE_FLOAT:
			value = x_value.value
		TYPE_STRING:
			value = string_parameter.text
		TYPE_VECTOR2:
			value = Vector2(x_value.value, y_value.value)
		TYPE_VECTOR3:
			value = Vector3(x_value.value, y_value.value, z_value.value)
		_:	# Unsupported data type
			value = _unsupported_value

	return {
		"name": _var_name,
		"value": value
	}

func _delete_all_but(type: int) -> void:
	match type:
		TYPE_BOOL:
			string_parameter.free()
			vector_parameter.free()
			unsupported_parameter.free()
		TYPE_INT, TYPE_FLOAT:
			boolean_parameter.free()
			string_parameter.free()
			y_value.free()
			z_value.free()
			unsupported_parameter.free()
		TYPE_STRING:
			boolean_parameter.free()
			vector_parameter.free()
			unsupported_parameter.free()
		TYPE_VECTOR2:
			boolean_parameter.free()
			string_parameter.free()
			z_value.free()
			unsupported_parameter.free()
		TYPE_VECTOR3:
			boolean_parameter.free()
			string_parameter.free()
			unsupported_parameter.free()
		_:	# Unsupported
			boolean_parameter.free()
			string_parameter.free()
			vector_parameter.free()
