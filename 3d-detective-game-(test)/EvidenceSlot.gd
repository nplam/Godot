# EvidenceSlot.gd - Complete updated version
extends PanelContainer

enum Mode { INVENTORY, CASE_BOARD }

var mode: Mode = Mode.INVENTORY
var evidence_id: String = ""
var evidence_data: Dictionary

# Node references
var label: Label
var icon: TextureRect
var remove_button: Button
var confirm_button: Button

# Signals
signal clicked(evidence_id)
signal confirmed(evidence_id)
signal removed(evidence_id)

func _ready():
	# Find all nodes
	label = find_child("Label", true, false)
	icon = _find_icon_node()
	remove_button = find_child("RemoveButton", true, false)
	confirm_button = find_child("ConfirmButton", true, false)
	
	# Setup icon appearance
	if icon:
		icon.custom_minimum_size = Vector2(64, 64)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Debug output
	_print_debug_info()

func _print_debug_info():
	print("\n🔍 EVIDENCE SLOT DEBUG - ", name)
	print("   Label: ", label)
	print("   Icon: ", icon)
	print("   Remove Button: ", remove_button)
	print("   Confirm Button: ", confirm_button)
	
	# Print all children for debugging
	print("   All children:")
	for child in get_children():
		print("     - ", child.name, " (", child.get_class(), ")")
		if child.get_child_count() > 0:
			for grandchild in child.get_children():
				print("       - ", grandchild.name, " (", grandchild.get_class(), ")")

func _find_icon_node() -> TextureRect:
	# Try to find "Icon" node first, fallback to "TextureRect"
	var icon_node = find_child("Icon", true, false)
	if icon_node and icon_node is TextureRect:
		return icon_node
	
	var texture_rect_node = find_child("TextureRect", true, false)
	if texture_rect_node and texture_rect_node is TextureRect:
		return texture_rect_node
	
	return null

func setup(data: Dictionary, new_mode: int):
	print("\n🔧 SETUP EVIDENCE SLOT - ", data.get("name", "Unknown"))
	
	# Find any missing nodes
	_find_missing_nodes()
	
	if not label:
		print("   ❌ CRITICAL: Label node not found!")
		return
	
	# Set evidence data
	evidence_id = data.get("id", "")
	evidence_data = data
	label.text = data.get("name", "Unknown")
	mode = new_mode
	
	# Setup icon texture
	_setup_icon(data)
	
	# Setup buttons based on mode
	_setup_buttons()
	
	print("   ✅ Setup complete - Mode: ", "INVENTORY" if mode == Mode.INVENTORY else "CASE_BOARD")

func _find_missing_nodes():
	if not label:
		label = find_child("Label", true, false)
		if label:
			print("   ✓ Found Label node")
	
	if not icon:
		icon = _find_icon_node()
		if icon:
			print("   ✓ Found Icon node")
	
	if not remove_button:
		remove_button = find_child("RemoveButton", true, false)
		if remove_button:
			print("   ✓ Found RemoveButton node")
	
	if not confirm_button:
		confirm_button = find_child("ConfirmButton", true, false)
		if confirm_button:
			print("   ✓ Found ConfirmButton node")

func _setup_icon(data: Dictionary):
	if not icon:
		print("   ⚠️ Icon node not available")
		return
	
	if data.has("texture") and data.texture:
		icon.texture = data.texture
		print("   ✓ Icon texture set: ", data.texture.resource_path)
		icon.modulate = Color(1, 1, 1, 1)
	else:
		icon.texture = null
		icon.modulate = Color(0.8, 0.8, 0.8, 1.0)
		print("   ⚠️ No texture provided, using default gray color")

func _setup_buttons():
	if mode == Mode.INVENTORY:
		_setup_inventory_mode()
	else:
		_setup_case_board_mode()

func _setup_inventory_mode():
	print("   📦 Setting up INVENTORY mode")
	
	if remove_button:
		remove_button.hide()
		_disconnect_button_signal(remove_button, _on_remove_pressed)
	else:
		print("   ⚠️ RemoveButton not found - skipping")
	
	if confirm_button:
		confirm_button.hide()
		_disconnect_button_signal(confirm_button, _on_confirm_pressed)
	else:
		print("   ⚠️ ConfirmButton not found - skipping")

func _setup_case_board_mode():
	print("   📋 Setting up CASE_BOARD mode")
	
	if remove_button:
		remove_button.show()
		_connect_button_signal(remove_button, _on_remove_pressed)
		print("   ✓ Remove button configured")
	else:
		print("   ❌ RemoveButton not found - cannot setup remove functionality!")
	
	if confirm_button:
		confirm_button.show()
		_connect_button_signal(confirm_button, _on_confirm_pressed)
		print("   ✓ Confirm button configured")
	else:
		print("   ❌ ConfirmButton not found - cannot setup confirm functionality!")

func _connect_button_signal(button: Button, callback: Callable):
	# Disconnect any existing connections first to avoid duplicates
	if button.pressed.is_connected(callback):
		button.pressed.disconnect(callback)
	# Connect the signal
	button.pressed.connect(callback)

func _disconnect_button_signal(button: Button, callback: Callable):
	if button.pressed.is_connected(callback):
		button.pressed.disconnect(callback)

func _on_remove_pressed():
	print("   🗑️ REMOVE button pressed for: ", evidence_id, " (", evidence_data.get("name", "Unknown"), ")")
	removed.emit(evidence_id)

func _on_confirm_pressed():
	print("   ✅ CONFIRM button pressed for: ", evidence_id, " (", evidence_data.get("name", "Unknown"), ")")
	confirmed.emit(evidence_id)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == Mode.INVENTORY:
			print("   🖱️ CLICKED on evidence slot: ", evidence_id, " (", evidence_data.get("name", "Unknown"), ")")
			clicked.emit(evidence_id)

# Helper function to update evidence data (useful for dynamic updates)
func update_evidence_data(data: Dictionary):
	evidence_data = data
	if label:
		label.text = data.get("name", "Unknown")
	_setup_icon(data)
	print("   🔄 Evidence data updated for: ", evidence_id)

# Helper function to check if buttons are working (for debugging)
func test_buttons():
	print("\n🧪 Testing buttons for evidence: ", evidence_id)
	print("   Remove button exists: ", remove_button != null)
	if remove_button:
		print("   Remove button visible: ", remove_button.visible)
		print("   Remove button disabled: ", remove_button.disabled)
		print("   Remove button signals: ", remove_button.pressed.get_connections())
	
	print("   Confirm button exists: ", confirm_button != null)
	if confirm_button:
		print("   Confirm button visible: ", confirm_button.visible)
		print("   Confirm button disabled: ", confirm_button.disabled)
		print("   Confirm button signals: ", confirm_button.pressed.get_connections())

# Clean up signals when the node is removed
func _exit_tree():
	if remove_button:
		if remove_button.pressed.is_connected(_on_remove_pressed):
			remove_button.pressed.disconnect(_on_remove_pressed)
	
	if confirm_button:
		if confirm_button.pressed.is_connected(_on_confirm_pressed):
			confirm_button.pressed.disconnect(_on_confirm_pressed)
