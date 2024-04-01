@tool
extends HBoxContainer

@onready var world_state_key_line_edit: LineEdit = %WorldStateKeyLineEdit
@onready var option_type_menu: OptionButton = %OptionTypeMenu
# Values
@onready var string_value: LineEdit = %StringValue
@onready var bool_value: CheckButton = %BoolValue
@onready var vector: HBoxContainer = %Vector
@onready var x_value: SpinBox = %XValue
@onready var y_value: SpinBox = %YValue
@onready var z_value: SpinBox = %ZValue

var _type_id: int
var _value
var _world_state_key: String

func initialize(world_state_key: StringName="", data: Dictionary={}) -> void:
	_hide_all()
	if data.is_empty():
		option_type_menu.select(0)
		_show(0)
	else:
		# Load data
		world_state_key_line_edit.text = world_state_key
		option_type_menu.select(data["type_id"])
		_show(data["type_id"])
		_load(data["type_id"], data["value"])
		_world_state_key = world_state_key
		_type_id = data["type_id"]
		_value = data["value"]

func get_data() -> Dictionary:
	return {
		"key": _world_state_key,
		"type_id": _type_id,
		"value": _value
	}

func _load(type_id: int, value) -> void:
	match type_id:
		0:	# Bool
			bool_value.button_pressed = value as bool
		1:	# Int
			x_value.value = value as int
		2:	# Float
			x_value.value = value as float
		3:	# String
			string_value.text = value as String
			string_value.placeholder_text = "Value"
		4:	# Vector2
			var vec: Vector2 = value as Vector2
			x_value.value = vec.x
			y_value.value = vec.y
		5:	# Vector3
			var vec: Vector3 = value as Vector3
			x_value.value = vec.x
			y_value.value = vec.y
			z_value.value = vec.z
		6:	# World State
			string_value.text = value as String
			string_value.placeholder_text = "World State Key"
		_:
			push_warning("Trying to set unknown type_id::", type_id)

func _hide_all() -> void:
	string_value.hide()
	bool_value.hide()
	vector.hide()
	x_value.hide()
	y_value.hide()
	z_value.hide()

func _show(idx: int) -> bool:
	_hide_all()
	match idx:
		0:	# Bool
			bool_value.show()
			_value = bool_value.button_pressed
		1:	# Int
			vector.show()
			x_value.show()
			x_value.step = 1
			_value = x_value.value
		2:	# Float
			vector.show()
			x_value.show()
			x_value.step = 0.1
			_value = x_value.value
		3:	# String
			string_value.show()
			string_value.text = ""
			string_value.placeholder_text = "Value"
		4:	# Vector2
			vector.show()
			x_value.show()
			x_value.step = 0.1
			y_value.show()
			y_value.step = 0.1
			_value = Vector2(x_value.value, y_value.value)
		5:	# Vector3
			vector.show()
			x_value.show()
			x_value.step = 0.1
			y_value.show()
			y_value.step = 0.1
			z_value.show()
			z_value.step = 0.1
			_value = Vector3(x_value.value, y_value.value, z_value.value)
		6:	# World State
			string_value.show()
			string_value.text = ""
			string_value.placeholder_text = "World State Key"
		_:
			push_warning("Somehow selected type_id::", idx)
			return false
	return true

func _on_option_type_menu_item_selected(index: int) -> void:
	_type_id = index
	if not _show(index):
		option_type_menu.select(0)	# Default to bool

func _on_delete_pressed() -> void:
	queue_free()

func _on_world_state_key_text_changed(new_text: String) -> void:
	_world_state_key = new_text

func _on_string_value_text_changed(new_text: String) -> void:
	_value = new_text

func _on_bool_value_toggled(toggled_on: bool) -> void:
	_value = toggled_on

func _on_x_value_value_changed(value: float) -> void:
	match _type_id:
		1, 2:
			_value = value
		4, 5:
			if _value is Vector2:
				_value.x = value
			else:
				_value = Vector2(value, 0)

func _on_y_value_value_changed(value: float) -> void:
	if _value is Vector2 or _value is Vector3:
		_value.y = value
	else:
		if _type_id == 4:	# Vector2
			_value = Vector2(0, value)
		elif _type_id == 5:	# Vector3
			_value = Vector3(0, value, 0)

func _on_z_value_value_changed(value: float) -> void:
	if _value is Vector3:
		_value.z = value
	else:
		_value = Vector3(0, 0, value)
