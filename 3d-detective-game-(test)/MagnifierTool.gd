# MagnifierTool.gd - Press 3 to equip, hold left to use
extends Node3D

var is_equipped: bool = false

func set_active(active: bool):
	is_equipped = active
	if not active:
		# If tool is deselected, make sure magnifier is off
		MagnifierManager.set_magnifier_active(false)
		print("🔍 Magnifier stowed")

func _process(delta):
	if not is_equipped:
		return
	
	# Check for left mouse button
	var left_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	# Show/hide magnifier based on left mouse
	MagnifierManager.set_magnifier_active(left_held)
	
	# Update position if magnifying
	if left_held:
		var mouse_pos = get_viewport().get_mouse_position()
		MagnifierManager.update_magnifier_position(mouse_pos)
