@tool
extends HBoxContainer

@onready var world_state_line_edit: LineEdit = %WorldStateLineEdit
@onready var compare_option_button: OptionButton = %CompareOptionButton
@onready var type_option_button: OptionButton = %TypeOptionButton
# Type Fields
@onready var is_true_toggle: CheckButton = %IsTrueToggle
@onready var string_value: LineEdit = %StringValue
@onready var vector_fields: HBoxContainer = %VectorFields
@onready var x_value: SpinBox = %XValue
@onready var y_value: SpinBox = %YValue
@onready var z_value: SpinBox = %ZValue

var _world_state_key: StringName
var _compare_id: int
var _type_id: int

func initialize(data: Dictionary={}) -> void:
	# Show Default
	_hide_all()

	if data.is_empty():	# Load Default Values
		compare_option_button.select(2)	# Default to Equal To
		_show_type_option(2)
	else:	# Load Data
		_load(data)

func get_data() -> Dictionary:
	return {
		"key": _world_state_key,
		"compare_id": _compare_id,
		"type_id": _type_id,
		"value": _cast_data()
	}

func _load(data: Dictionary) -> void:
	world_state_line_edit.text = data["key"]
	_world_state_key = data["key"]
	compare_option_button.select(data["compare_id"])
	_compare_id = data["compare_id"]
	type_option_button.select(data["type_id"])
	_show_type_field(data["type_id"])
	match data["type_id"]:
		0:
			is_true_toggle.button_pressed = data["value"]
		1, 2:
			x_value.value = data["value"]
		3, 6:
			string_value.text = data["value"]
		4:
			x_value.value = data["value"].x
			y_value.value = data["value"].y
		5:
			x_value.value = data["value"].x
			y_value.value = data["value"].y
			z_value.value = data["value"].z

func _cast_data():
	match _type_id:
		0:	# Boolean
			return is_true_toggle.button_pressed
		1:	# Int
			return int(x_value.value)
		2:	# Float
			return float(x_value.value)
		3, 6:	# String, World State Key
			return string_value.text
		4:	# Vector2
			return Vector2(x_value.value, y_value.value)
		5:	# Vector3
			return Vector3(x_value.value, y_value.value, z_value.value)
		_:
			assert(false, "Type ID: " + str(_type_id) + " is invalid.")

func _hide_all() -> void:
	is_true_toggle.hide()
	string_value.hide()
	vector_fields.hide()
	x_value.hide()
	y_value.hide()
	z_value.hide()

func _show_type_option(idx: int) -> void:
	_compare_id = idx
	_hide_all()
	match idx:
		0, 1, 3, 4:	# >, <, >=, <= :: int, float, vector2, vector3, world state
			type_option_button.set_item_disabled(0, true)
			type_option_button.set_item_disabled(3, true)
			if type_option_button.selected == 0:
				type_option_button.select(1)
			elif type_option_button.selected == 3:
				type_option_button.select(6)
			_show_type_field(type_option_button.selected)
		2:	# == :: bool, int, float, string, vector2, vector3, world state
			type_option_button.set_item_disabled(0, false)
			type_option_button.set_item_disabled(3, false)
			_show_type_field(type_option_button.selected)

# bool, int, float, string, vector2, vector3, world state
func _show_type_field(idx: int) -> void:
	_hide_all()

	# Sets Default Value
	match idx:
		0:	# Boolean
			is_true_toggle.show()
			is_true_toggle.button_pressed = true
		1:	# Int
			vector_fields.show()
			_show_x_field(true)
		2:	# Float
			vector_fields.show()
			_show_x_field(false)
		3:	# String
			_show_string(true)
		4:	# Vector2
			vector_fields.show()
			_show_x_field(false)
			_show_y_field()
		5:	# Vector3
			vector_fields.show()
			_show_x_field(false)
			_show_y_field()
			_show_z_field()
		6:	# World State
			_show_string(false)
	_type_id = idx

func _show_string(is_normal) -> void:
	string_value.show()
	string_value.text = ""
	if is_normal:
		string_value.placeholder_text = "Value"
	else:
		string_value.placeholder_text = "World State Key"

func _show_x_field(is_int: bool=false) -> void:
	x_value.show()
	if is_int:
		x_value.step = 1
		x_value.value = 0
	else:
		x_value.step = 0.1
		x_value.value = 0.0

func _show_y_field() -> void:
	y_value.show()
	y_value.step = 0.1
	y_value.value = 0.0

func _show_z_field() -> void:
	z_value.show()
	z_value.step = 0.1
	z_value.value = 0.0

func _on_delete_button_pressed() -> void:
	queue_free()

func _on_world_state_line_edit_text_changed(new_text: String) -> void:
	_world_state_key = new_text

func _on_option_button_item_selected(index: int) -> void:
	_show_type_option(index)

func _on_type_option_button_item_selected(index: int) -> void:
	_show_type_field(index)
