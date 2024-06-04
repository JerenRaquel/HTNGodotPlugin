@tool
class_name HTNConditionLine
extends VBoxContainer

## Compare IDs
#0:	# Greater Than
#1:	# Less Than
#2:	# Equal To
#3:	# Greater Than or Equal To
#4:	# Less Than or Equal To
#5:	# Range

# Options
@onready var range_type_option: OptionButton = %RangeTypeOption
@onready var single_type_option: OptionButton = %SingleTypeOption
# Data
@onready var data_container: HBoxContainer = %DataContainer
@onready var is_true_toggle: CheckButton = %IsTrueToggle
@onready var string_value: LineEdit = %StringValue
@onready var x_value: SpinBox = %XValue
@onready var y_value: SpinBox = %YValue
@onready var z_value: SpinBox = %ZValue
# Labels
@onready var x_label: Label = %XLabel
@onready var y_label: Label = %YLabel
@onready var z_label: Label = %ZLabel
# CheckBoxes
@onready var x_check_box: CheckBox = %XCheckBox
@onready var y_check_box: CheckBox = %YCheckBox
# Other
@onready var range_separator: HSeparator = %RangeSeparator

var _compare_type: int

func initialize(data: Dictionary = {}) -> void:
	data_container.hide()
	if data.is_empty():
		_show_based_on_compare_type(0)
	else:	# Load data
		pass

func _show_based_on_compare_type(idx: int) -> void:
	_compare_type = idx
	match idx:
		0, 1, 2, 3, 4:	# Less Than
			range_type_option.hide()
			single_type_option.show()
		5:	# Range
			range_type_option.show()
			single_type_option.hide()
			_show_spin_box(0, "Start", true, true)
			_show_spin_box(1, "End", true, true)
			range_separator.show()
			data_container.show()

func _show_spin_box(component_idx: int, label_text: String, is_rounded: bool, enable_checkbox: bool) -> void:
	var spin_box: SpinBox
	var label: Label
	match component_idx:
		0:	# X
			spin_box = x_value
			label = x_label
			if enable_checkbox: x_check_box.show()
		1:	# Y
			spin_box = y_value
			label = y_label
			if enable_checkbox: y_check_box.show()
		2:	# Z
			spin_box = z_value
			label = z_label
	# SpinBox
	spin_box.step = 1 if is_rounded else 0.1
	spin_box.rounded = is_rounded
	spin_box.show()
	# Label
	label.text = label_text
	label.show()

func _on_delete_button_pressed() -> void:
	queue_free()

func _on_compare_option_item_selected(index: int) -> void:
	_show_based_on_compare_type(index)

func _on_range_type_option_item_selected(index: int) -> void:
	# True: Int | False: Float
	_show_spin_box(0, "Start", true if index == 0 else false, true)
	_show_spin_box(1, "End", true if index == 0 else false, true)

func _on_single_type_option_item_selected(index: int) -> void:
	pass # Replace with function body.

func _on_data_container_hidden() -> void:
	is_true_toggle.hide()
	string_value.hide()
	x_value.hide()
	y_value.hide()
	z_value.hide()
	x_label.hide()
	y_label.hide()
	z_label.hide()
	x_check_box.hide()
	y_check_box.hide()
	range_separator.hide()
