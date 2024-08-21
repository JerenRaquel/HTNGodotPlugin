@tool
class_name HTNConditionLine
extends MarginContainer

const ERROR: CompressedTexture2D = preload("res://addons/HTNDomainManager/PluginSystem/Icons/Error.svg")
const SMILEY: CompressedTexture2D = preload("res://addons/HTNDomainManager/PluginSystem/Icons/Smiley.svg")
const VALID_COMPARE_TOKENS: Array[String] = [ ">", "<", "==", "!=", ">=", "<=" ]

## Single Type IDs
#4:	# Vector2
#5:	# Vector3

@onready var validation_icon: TextureRect = %ValidationIcon
@onready var line_edit: LineEdit = %LineEdit

func initialize(data: Array = []) -> void:
	if not data.is_empty():
		_load_data(data)
	_on_line_edit_text_changed(line_edit.text)

func get_data() -> Array[Variant]:
	if not _validate(line_edit.text).is_empty(): return []
	return _tokenize(line_edit.text)

func _load_data(data: Array) -> void:
	var text: String = ""
	var idx: int = 0
	for token: Variant in data:
		text += str(token)
		if idx < data.size()-1:
			text += " "
		idx += 1

	line_edit.text = text

func _tokenize(text: String) -> Array[Variant]:
	var args: PackedStringArray = text.split(" ", false)
	var data: Array[Variant] = []

	for arg: String in args:
		if arg in VALID_COMPARE_TOKENS:
			data.push_back(arg)
		elif arg.is_valid_float():
			data.push_back(float(arg))
		elif arg.is_valid_int():
			data.push_back(int(arg))
		elif arg == "true":
			data.push_back(true)
		elif arg == "false":
			data.push_back(false)
		elif _is_vector(arg):
			data.push_back(_convert_to_vector(arg))
		else:
			data.push_back(arg)
	return data

func _is_vector(arg: String) -> bool:
	if not arg.begins_with("(") and not arg.begins_with(")"): return false

	var tokens: PackedStringArray = arg.substr(1, arg.length()-2).split(",", false)
	if tokens.size() < 2 or tokens.size() > 3: return false

	var all_ints: bool = true
	for token: String in tokens:
		if token.is_valid_int(): continue
		if token.is_valid_float():
			all_ints = false
			continue
		return false

	return true

func _convert_to_vector(arg: String) -> Array[Variant]:
	var tokens: PackedStringArray = arg.substr(1, arg.length()-2).split(",", false)
	var all_ints: bool = true
	for token: String in tokens:
		if token.is_valid_int(): continue
		if token.is_valid_float():
			all_ints = false
			continue
		break

	var parts: Array[Variant] = []
	for token: String in tokens:
		if all_ints:
			parts.push_back(int(token))
		else:
			parts.push_back(float(token))

	return parts

func _validate(new_text: String) -> String:
	var args: PackedStringArray = new_text.split(" ", false)
	var argc: int = args.size()

	# Check arg size
	if argc < 3:
		return "Condition args need to be separated by spaces..."
	if argc == 4 or argc > 5:
		return "Condition args need to have a count of 3 or 5. ie. $example == null | 4 < $example <= 10.2"

	# Check compare symbols
	if argc == 3:
		if args[1] not in VALID_COMPARE_TOKENS:
			return "Condition arg [" + args[1] + "] is not a valid compare symbol..."
	if argc == 5:
		if args[3] not in VALID_COMPARE_TOKENS:
			return "Condition arg [" + args[3] + "] is not a valid compare symbol..."

	# Check for range pairs, if applicable
	if argc == 5:
		if args[1].begins_with("<") and not args[3].begins_with("<"):
			return "A Conditional Range must have a consistent direction.\nThe comparison arrows point in the same direction."
		if args[1].begins_with(">") and not args[3].begins_with(">"):
			return "A Conditional Range must have a consistent direction.\nThe comparison arrows point in the same direction."

	# Check for a valid world state
	var contains_world_state: bool = false
	for arg: String in args:
		if arg.begins_with("$") and arg.length() > 1:
			contains_world_state = true
			break
	if not contains_world_state:
		return "Condition must include at least 1 WorldState key..."

	# Check for valid tokens
	if args[0] in VALID_COMPARE_TOKENS:
		return "First conditional token can not be a comparison symbol..."
	elif args[2] in VALID_COMPARE_TOKENS:
		return "Second conditional token can not be a comparison symbol..."
	elif argc == 5 and args[4] in VALID_COMPARE_TOKENS:
		return "Fifth conditional token can not be a comparison symbol..."

	# Check for vector bracket pairs
	for arg: String in args:
		if arg.begins_with("(") and _is_vector(arg): continue
		if arg.ends_with(")"): return "Ending Bracket [)] fround with no beginning counterpart..."

	return ""

func _error(message: String) -> void:
	validation_icon.texture = ERROR
	validation_icon.tooltip_text = message

func _ok(message: String) -> void:
	validation_icon.texture = SMILEY
	validation_icon.tooltip_text = message

func _on_delete_button_pressed() -> void:
	queue_free()

func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		_error("Condition can not be empty...")
		return

	var error_message: String = _validate(new_text)
	if error_message.is_empty():
		_ok("Condition is valid...")
	else:
		_error(error_message)
