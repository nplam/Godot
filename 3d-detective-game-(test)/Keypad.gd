# Keypad.gd - Clean version with no debug visuals
extends Area3D

@export var door: Node3D
@export var correct_code: String = "1234"

var current_input: String = ""
var is_open: bool = false

@onready var display: Label3D = $Display

func _ready():
	add_to_group("interactable")
	print("🔢 Keypad ready")

func get_interaction_text() -> String:
	if is_open:
		return "Door is open"
	return "Use Keypad"

func interact():
	if is_open:
		return
	print("Enter code (type numbers, press Enter)")

func _input(event):
	if not has_focus():
		return
	if is_open:
		return
	
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		if key >= KEY_0 and key <= KEY_9:
			current_input += char(key)
			update_display()
			print("Code: ", current_input)
		elif key == KEY_ENTER:
			verify_code()
		elif key == KEY_BACKSPACE and current_input.length() > 0:
			current_input = current_input.substr(0, current_input.length() - 1)
			update_display()

func update_display():
	var text = current_input
	while text.length() < 4:
		text = "_" + text
	display.text = text

func verify_code():
	if current_input == correct_code:
		print("✅ Correct code!")
		if door and door.has_method("open"):
			door.open()
		is_open = true
	else:
		print("❌ Wrong code!")
		current_input = ""
		update_display()

func has_focus() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	return player and player.current_interactable == self
