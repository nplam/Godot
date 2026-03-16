# UVLight.gd - Handles UV light toggling and evidence detection (blood + shoeprints)
extends Area3D

# References to our child nodes
# References to our child nodes
@onready var visual_light: SpotLight3D = $"../UVLight"
@onready var detection_area: Area3D = get_node(".")  # Explicitly get node as Area3D
@onready var hand: Node3D = $".."
	
# Track whether the light is on
var is_on: bool = false
var detected_evidence: Array = []  # Keep track of all evidence currently in the light

func _ready():
	print("🔦 UVLight _ready() starting...")
	print("   Node path: ", get_path())
	print("   Children: ", get_children())
	print("   visual_light = ", visual_light)
	print("   detection_area = ", detection_area)
	
	# Start with light off
	if visual_light:
		visual_light.visible = false
	else:
		print("⚠️ visual_light is null - check that ../UVLight exists!")
	
	detection_area.monitoring = false  # This node IS the detection area
	
	# Connect detection signals
	detection_area.area_entered.connect(_on_area_entered)
	detection_area.area_exited.connect(_on_area_exited)
	
	# Debug detection area position
	print("🔍 Detection Area Debug:")
	print("   Global position: ", detection_area.global_position)
	print("   Local position: ", detection_area.position)
	
	# FIXED: Use the correct path to CollisionShape3D
	var shape_node = $CollisionShape3D
	if shape_node:
		print("   CollisionShape3D position: ", shape_node.position)
		print("   CollisionShape3D scale: ", shape_node.scale)
		if shape_node.shape:
			print("   Shape type: ", shape_node.shape.get_class())
			if shape_node.shape is CylinderShape3D:
				print("   Cylinder radius: ", shape_node.shape.radius)
				print("   Cylinder height: ", shape_node.shape.height)
			elif shape_node.shape is BoxShape3D:
				print("   Box size: ", shape_node.shape.size)
		else:
			print("   ⚠️ No shape assigned!")
	else:
		print("   ❌ CollisionShape3D not found!")
	
	print("🔦 UV Light system ready on Hand node")
	
	# Rotate the detection area to point forward (if cylinder)
	if shape_node and shape_node.shape is CylinderShape3D:
		shape_node.rotation_degrees = Vector3(90, 0, 0)
		print("✅ Detection area rotated to point forward")
		shape_node.shape.radius = 0.8
		shape_node.shape.height = 3.0
	
func _input(event):
	if event.is_action_pressed("toggle_uv"):
		toggle_light()

func toggle_light():
	is_on = !is_on
	visual_light.visible = is_on
	detection_area.monitoring = is_on
	
	if is_on:
		print("🔦 Light turned ON")
		debug_self()
	else:
		print("UV Light OFF")
		reset_all_evidence()  # Hide all evidence when light turns off

# Debug function to print current layer/mask configuration
func debug_self():
	print("🔍 UV Light System Debug:")
	print("   is_on: ", is_on)
	print("   Detection Area:")
	print("      Layer: ", detection_area.collision_layer)
	var layers = []
	for i in range(1, 6):
		if detection_area.get_collision_layer_value(i):
			layers.append(str(i))
	print("      Active Layers: ", "Layer " + ", Layer ".join(layers) if layers else "None")
	
	print("      Mask: ", detection_area.collision_mask)
	var masks = []
	for i in range(1, 6):
		if detection_area.get_collision_mask_value(i):
			masks.append(str(i))
	print("      Active Masks: ", "Layer " + ", Layer ".join(masks) if masks else "None")

# Debug function for entering areas
func debug_area(area: Area3D, prefix: String = ""):
	print(prefix, "Area Debug:")
	print(prefix, "   Name: ", area.name)
	print(prefix, "   Class: ", area.get_class())
	print(prefix, "   Groups: ", area.get_groups())
	print(prefix, "   Collision Layer: ", area.collision_layer)
	
	var area_layers = []
	for i in range(1, 6):
		if area.get_collision_layer_value(i):
			area_layers.append(str(i))
	print(prefix, "   Active Layers: ", "Layer " + ", Layer ".join(area_layers) if area_layers else "None")
	
	if area.has_method("on_uv_detected"):
		print(prefix, "   ✅ Has on_uv_detected method")
	else:
		print(prefix, "   ❌ Missing on_uv_detected method")

func _on_area_entered(area: Area3D):
	print("\n=== AREA ENTERED ===")
	print("Time: ", Time.get_time_string_from_system())
	print("🔦 UV Light area entered: ", area.name)
	
	# Debug the entering area
	debug_area(area, "   ")
	
	# Debug our detection area
	print("   Detection Area Status:")
	print("      Monitoring: ", detection_area.monitoring)
	print("      Layer: ", detection_area.collision_layer)
	print("      Mask: ", detection_area.collision_mask)
	
	# Check for blood stains
	if area.is_in_group("blood_stain") and area.has_method("on_uv_detected"):
		print("   ✅ Blood stain detected!")
		if not area in detected_evidence:
			detected_evidence.append(area)
			area.on_uv_detected()
			print("   🩸 Blood stain added. Total: ", detected_evidence.size())
		else:
			print("   ⚠️ Blood stain already in list")
	
	# Check for shoeprints
	elif area.is_in_group("shoeprint") and area.has_method("on_uv_detected"):
		print("   ✅ Shoeprint detected!")
		if not area in detected_evidence:
			detected_evidence.append(area)
			area.on_uv_detected()
			print("   👣 Shoeprint added. Total: ", detected_evidence.size())
		else:
			print("   ⚠️ Shoeprint already in list")
	else:
		print("   ❌ Not a valid evidence type")
		if not area.is_in_group("blood_stain") and not area.is_in_group("shoeprint"):
			print("      - Wrong group")
		if not area.has_method("on_uv_detected"):
			print("      - Missing on_uv_detected method")
	
	print("=== END ===\n")

func _on_area_exited(area: Area3D):
	print("\n=== AREA EXITED ===")
	print("Area: ", area.name)
	
	if area in detected_evidence:
		detected_evidence.erase(area)
		if area.has_method("reset_glow"):
			area.reset_glow()
		print("   👋 Evidence removed. Remaining: ", detected_evidence.size())
	else:
		print("   ⚠️ Area was not in detected list")
	print("=== END ===\n")

# Helper to hide all evidence when light turns off
func reset_all_evidence():
	print("🔄 Resetting all evidence")
	for evidence in detected_evidence:
		if is_instance_valid(evidence) and evidence.has_method("reset_glow"):
			evidence.reset_glow()
			print("   Reset: ", evidence.name)
	detected_evidence.clear()

# Called by Player.gd when selecting tools
func set_active(active: bool):
	is_on = active
	visual_light.visible = active
	detection_area.monitoring = active
	if active:
		print("🔦 UV Light activated by tool selection")
		debug_self()

# Add this at the bottom of your script
func _process(delta):
	if is_on and Input.is_key_pressed(KEY_P):  # Press P to debug
		print("\n=== DETECTION AREA DEBUG (P pressed) ===")
		print("Detection Area global position: ", detection_area.global_position)
		print("Hand global position: ", hand.global_position)
		print("Camera global position: ", get_viewport().get_camera_3d().global_position)
		print("Distance from camera: ", detection_area.global_position.distance_to(get_viewport().get_camera_3d().global_position))
		
		# Get the shape info - FIXED path here too
		var shape_node = $CollisionShape3D
		if shape_node and shape_node.shape:
			print("Shape type: ", shape_node.shape.get_class())
			if shape_node.shape is CylinderShape3D:
				print("   Cylinder radius: ", shape_node.shape.radius)
				print("   Cylinder height: ", shape_node.shape.height)
			elif shape_node.shape is BoxShape3D:
				print("   Box size: ", shape_node.shape.size)
		
		# Check what's overlapping right now
		var overlapping = detection_area.get_overlapping_areas()
		print("Currently overlapping areas: ", overlapping.size())
		for area in overlapping:
			print("   - ", area.name, " (Groups: ", area.get_groups(), ")")
		
		print("=== END DEBUG ===\n")
