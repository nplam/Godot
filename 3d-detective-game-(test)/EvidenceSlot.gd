# EvidenceSlot.gd - Updated version (test texture removed)
extends PanelContainer

enum Mode { INVENTORY, CASE_BOARD }

var mode: Mode = Mode.INVENTORY
var evidence_id: String = ""
var evidence_data: Dictionary

# Node references - Updated paths for your structure
var label: Label
var icon: TextureRect
var remove_button: Button
var confirm_button: Button
var selection_highlight: ColorRect

# Signals
signal clicked(evidence_id)
signal confirmed(evidence_id)
signal removed(evidence_id)

func _ready():
	# Find all nodes - UPDATED PATHS for your structure
	label = $MarginContainer/VBoxContainer/Label
	icon = $MarginContainer/VBoxContainer/Icon
	remove_button = find_child("RemoveButton", true, false)
	confirm_button = find_child("ConfirmButton", true, false)
	
	print("\n🔍 EVIDENCE SLOT _ready - Structure debug:")
	print("   Label found: ", label != null)
	print("   Icon found: ", icon != null)
	if icon:
		print("   Icon node: ", icon.name)
	
	# Setup icon appearance
	if icon:
		icon.custom_minimum_size = Vector2(64, 64)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Create selection highlight overlay
	_create_selection_highlight()
	
	# Setup tooltip
	tooltip_text = "Click to select this evidence for placement"

func _create_selection_highlight():
	"""Create a highlight overlay for when evidence is selected"""
	selection_highlight = ColorRect.new()
	selection_highlight.color = Color(1, 1, 0, 0.3)
	selection_highlight.size = size
	selection_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_highlight.hide()
	add_child(selection_highlight)

func _find_icon_node() -> TextureRect:
	"""Fallback method to find icon"""
	var direct_icon = $MarginContainer/VBoxContainer/Icon
	if direct_icon:
		return direct_icon
	
	var icon_node = find_child("Icon", true, false)
	if icon_node and icon_node is TextureRect:
		return icon_node
	
	var texture_rect_node = find_child("TextureRect", true, false)
	if texture_rect_node and texture_rect_node is TextureRect:
		return texture_rect_node
	
	return null

func setup(data: Dictionary, new_mode: int):
	print("\n🔧 SETUP EVIDENCE SLOT - ", data.get("name", "Unknown"))
	
	# DEBUG: Print all data keys and texture info
	print("   📦 Evidence data received:")
	print("      Keys: ", data.keys())
	print("      Has 'texture'? ", data.has("texture"))
	if data.has("texture"):
		print("      Texture value: ", data.texture)
		if data.texture:
			print("      Texture resource path: ", data.texture.resource_path)
		else:
			print("      Texture is null!")
	
	# Make sure we have references
	if not label:
		label = $MarginContainer/VBoxContainer/Label
	if not icon:
		icon = $MarginContainer/VBoxContainer/Icon
		print("   Icon found in setup: ", icon != null)
	
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
	
	# Set tooltip
	tooltip_text = data.get("name", "Unknown") + "\n" + data.get("description", "Click to select this evidence")
	
	print("   ✅ Setup complete - Mode: ", "INVENTORY" if mode == Mode.INVENTORY else "CASE_BOARD")

func _setup_icon(data: Dictionary):
	if not icon:
		print("   ⚠️ Icon node not available!")
		return
	
	print("   🖼️ Setting up icon...")
	
	if data.has("texture") and data.texture:
		icon.texture = data.texture
		print("   ✓ Icon texture set from data")
		print("      Texture path: ", data.texture.resource_path if data.texture else "none")
		icon.modulate = Color(1, 1, 1, 1)
		
		# Verify texture was applied
		if icon.texture:
			print("      ✅ Icon texture verified")
		else:
			print("      ❌ Icon texture is null after assignment!")
	else:
		print("   ⚠️ No texture provided in data!")
		print("   Using default gray color")
		icon.texture = null
		icon.modulate = Color(0.8, 0.8, 0.8, 1.0)

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
	
	if confirm_button:
		confirm_button.hide()
		_disconnect_button_signal(confirm_button, _on_confirm_pressed)

func _setup_case_board_mode():
	print("   📋 Setting up CASE_BOARD mode")
	
	if remove_button:
		remove_button.show()
		_connect_button_signal(remove_button, _on_remove_pressed)
		print("   ✓ Remove button configured")
	else:
		print("   ⚠️ RemoveButton not found")
	
	if confirm_button:
		confirm_button.show()
		_connect_button_signal(confirm_button, _on_confirm_pressed)
		print("   ✓ Confirm button configured")
	else:
		print("   ⚠️ ConfirmButton not found")

func _connect_button_signal(button: Button, callback: Callable):
	if button.pressed.is_connected(callback):
		button.pressed.disconnect(callback)
	button.pressed.connect(callback)

func _disconnect_button_signal(button: Button, callback: Callable):
	if button.pressed.is_connected(callback):
		button.pressed.disconnect(callback)

func _on_remove_pressed():
	print("   🗑️ REMOVE button pressed for: ", evidence_id)
	removed.emit(evidence_id)

func _on_confirm_pressed():
	print("   ✅ CONFIRM button pressed for: ", evidence_id)
	confirmed.emit(evidence_id)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == Mode.INVENTORY:
			print("   🖱️ CLICKED on evidence: ", evidence_data.get("name", "Unknown"))
			clicked.emit(evidence_id)

func set_selected(selected: bool):
	if selection_highlight:
		if selected:
			selection_highlight.show()
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		else:
			selection_highlight.hide()
			modulate = Color(1, 1, 1, 1)

func show_placement_feedback(is_correct: bool):
	var original_modulate = modulate
	
	if is_correct:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(0.3, 1, 0.3, 1), 0.2)
		tween.tween_property(self, "modulate", original_modulate, 0.2)
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 0.3, 0.3, 1), 0.2)
		tween.tween_property(self, "modulate", original_modulate, 0.2)
		
		var shake_tween = create_tween()
		shake_tween.tween_property(self, "position", Vector2(5, 0), 0.05)
		shake_tween.tween_property(self, "position", Vector2(-5, 0), 0.05)
		shake_tween.tween_property(self, "position", Vector2(0, 0), 0.05)

func update_evidence_data(data: Dictionary):
	evidence_data = data
	if label:
		label.text = data.get("name", "Unknown")
	_setup_icon(data)
	tooltip_text = data.get("name", "Unknown") + "\n" + data.get("description", "")

func _exit_tree():
	if remove_button:
		if remove_button.pressed.is_connected(_on_remove_pressed):
			remove_button.pressed.disconnect(_on_remove_pressed)
	
	if confirm_button:
		if confirm_button.pressed.is_connected(_on_confirm_pressed):
			confirm_button.pressed.disconnect(_on_confirm_pressed)
	
	if selection_highlight:
		selection_highlight.queue_free()
