# BlueLight_New.gd - Complete version with detection area debug
extends Area3D

# References
var is_on: bool = false
var visual_light: SpotLight3D = null
var glasses_overlay = null

func _ready():
	print("\n=== BLUE LIGHT INITIALIZING ===")
	
	# Find the visual light node
	var parent = get_parent()
	if parent:
		print("Parent found: ", parent.name)
		for child in parent.get_children():
			print("  Child: ", child.name, " (", child.get_class(), ")")
			if child.name == "BlueLight" and child is SpotLight3D:
				visual_light = child
				print("  ✅ Found BlueLight visual")
				break
	
	# Find glasses overlay
	glasses_overlay = get_tree().root.find_child("OrangeGlassesOverlay", true, false)
	print("Glasses overlay: ", glasses_overlay)
	
	# TEMPORARY: Make detection area massive for testing
	var shape_node = $CollisionShape3D
	if shape_node and shape_node.shape:
		print("Original shape: ", shape_node.shape.get_class())
		if shape_node.shape is BoxShape3D:
			var old_size = shape_node.shape.size
			shape_node.shape.size = Vector3(5.0, 5.0, 10.0)
			print("🔧 Box shape size changed from ", old_size, " to ", shape_node.shape.size)
		elif shape_node.shape is CylinderShape3D:
			var old_radius = shape_node.shape.radius
			var old_height = shape_node.shape.height
			shape_node.shape.radius = 3.0
			shape_node.shape.height = 10.0
			print("🔧 Cylinder changed: radius ", old_radius, "->3.0, height ", old_height, "->10.0")
	
	# Print detection area position
	print("Detection Area local position: ", position)
	print("Detection Area global position: ", global_position)
	
	# Start disabled
	if visual_light:
		visual_light.visible = false
		print("Visual light disabled")
	monitoring = false
	print("Monitoring disabled")
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	print("Signal connected")
	
	print("=== BLUE LIGHT READY ===\n")

func set_active(active: bool):
	print("\n🔵 set_active(", active, ") called")
	print("   Current visual_light: ", visual_light)
	
	is_on = active
	
	# Control visual light
	if visual_light:
		visual_light.visible = active
		print("   ✅ Visual light set to ", active)
	else:
		print("   ⚠️ visual_light null - searching...")
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child.name == "BlueLight" and child is SpotLight3D:
					visual_light = child
					visual_light.visible = active
					print("   ✅ Found and set visual light")
					break
	
	monitoring = active
	print("   Monitoring set to ", active)
	print("🔵 Blue Light active: ", active)

func _on_area_entered(area: Area3D):
	print("\n🔵 AREA ENTERED: ", area.name)
	print("   is_on: ", is_on)
	print("   area class: ", area.get_class())
	print("   area groups: ", area.get_groups())
	print("   area layer: ", area.collision_layer)
	print("   area position: ", area.global_position)
	
	if not is_on:
		print("   ❌ Light is off - ignoring")
		return
	
	# Check glasses
	var glasses_on = glasses_overlay and glasses_overlay.is_on if glasses_overlay else false
	print("   glasses_on: ", glasses_on)
	
	if not glasses_on:
		print("   ❌ Glasses off - fingerprint invisible")
		return
	
	print("   ✅ Glasses on - can detect")
	print("   Checking if fingerprint surface...")
	
	if area.is_in_group("fingerprint_surface"):
		print("      ✅ In fingerprint_surface group")
		if area.has_method("on_blue_light_detected"):
			print("      ✅ Has detection method")
			print("      🔵 Calling on_blue_light_detected()")
			area.on_blue_light_detected()
		else:
			print("      ❌ Missing on_blue_light_detected method")
	else:
		print("      ❌ Not in fingerprint_surface group")
	
	print("=== END AREA ENTERED ===\n")

func _process(delta):
	if is_on and Input.is_key_pressed(KEY_P):
		print("\n=== DETECTION AREA DEBUG (P pressed) ===")
		print("Detection Area local position: ", position)
		print("Detection Area global position: ", global_position)
		print("Overlapping areas: ", get_overlapping_areas().size())
		var overlapping = get_overlapping_areas()
		for area in overlapping:
			print("   - ", area.name, " at ", area.global_position)
		print("=== END DEBUG ===\n")
