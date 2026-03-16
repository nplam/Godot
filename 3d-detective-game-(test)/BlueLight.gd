# BlueLight.gd - Production version with minimal but essential debug
extends Area3D

# Add at the top of the file, outside any function
static var instance_count = 0

@onready var visual_light: SpotLight3D = $"../BlueLight"
@onready var detection_area: Area3D = get_node(".")  # Explicitly get node as Area3D
@onready var hand: Node3D = $".."

var is_on: bool = false
var glasses_overlay: ColorRect = null

func _init():
	instance_count += 1
	print("🔵 BlueLight instance created. Total instances: ", instance_count)
	print("🔵 My name: ", name)
	print("🔵 My path: ", get_path())

func _ready():
	print("🔵🔵🔵 BLUE LIGHT _READY() EXECUTING 🔵🔵🔵")
	
	# Start with light off
	if visual_light:
		visual_light.visible = false
	else:
		print("⚠️ visual_light is null - check that ../BlueLight exists!")
	
	detection_area.monitoring = false
	
	# Configure blue light properties
	if visual_light:
		visual_light.light_color = Color(0.27, 0.53, 1.0)  # Bright blue #4488FF
		visual_light.light_energy = 1.5
		visual_light.spot_range = 5.0
		visual_light.spot_angle = 45.0
	
	# Connect detection signal
	detection_area.area_entered.connect(_on_area_entered)
	
	# Find glasses overlay once at startup
	glasses_overlay = get_tree().root.find_child("OrangeGlassesOverlay", true, false)
	if glasses_overlay:
		print("🔵 Blue Light ready - glasses overlay found")
	else:
		print("🔵 Blue Light ready - glasses overlay not found (will check at detection time)")
	
	# CRITICAL DEBUG: Print detection area configuration
	print("\n=== BLUE LIGHT CONFIGURATION ===")
	print("Detection Area monitoring: ", detection_area.monitoring)
	print("Detection Area position (local): ", detection_area.position)
	print("Detection Area position (global): ", detection_area.global_position)
	print("Detection Area layer: ", detection_area.collision_layer)
	print("Detection Area mask: ", detection_area.collision_mask)
	
	# FIXED: Direct child path
	var shape_node = $CollisionShape3D
	if shape_node:
		print("CollisionShape3D position: ", shape_node.position)
		print("CollisionShape3D scale: ", shape_node.scale)
		if shape_node.shape:
			print("Shape type: ", shape_node.shape.get_class())
			if shape_node.shape is CylinderShape3D:
				print("  Cylinder radius: ", shape_node.shape.radius)
				print("  Cylinder height: ", shape_node.shape.height)
			elif shape_node.shape is BoxShape3D:
				print("  Box size: ", shape_node.shape.size)
		else:
			print("  ⚠️ No shape assigned!")
	else:
		print("  ❌ CollisionShape3D not found!")
	print("=== END CONFIG ===\n")

func set_active(active: bool):
	is_on = active
	if visual_light:
		visual_light.visible = active
	detection_area.monitoring = active
	print("🔵 Blue Light active: ", active, " | Monitoring: ", detection_area.monitoring)
	
	# Print configuration every time we activate
	if active:
		print("\n=== BLUE LIGHT CONFIGURATION (on activate) ===")
		print("Detection Area global position: ", detection_area.global_position)
		print("Detection Area local position: ", detection_area.position)
		print("Detection Area layer: ", detection_area.collision_layer)
		print("Detection Area mask: ", detection_area.collision_mask)

func _on_area_entered(area: Area3D):
	if not is_on:
		return
	
	# Check if orange glasses are on
	var glasses_on = false
	
	# Try cached reference first
	if glasses_overlay and glasses_overlay.is_on:
		glasses_on = true
	else:
		# Fallback: search for glasses if not found yet
		var glasses = get_tree().root.find_child("OrangeGlassesOverlay", true, false)
		if glasses and glasses.is_on:
			glasses_on = true
			glasses_overlay = glasses  # Cache for next time
	
	if not glasses_on:
		return  # Fingerprints invisible without glasses
	
	# Detect fingerprint surfaces
	if area.is_in_group("fingerprint_surface") and area.has_method("on_blue_light_detected"):
		print("🔵 Fingerprint detected: ", area.name)
		area.on_blue_light_detected()

func _process(delta):
	if is_on and Input.is_key_pressed(KEY_P):
		var overlapping = detection_area.get_overlapping_areas()
		print("Overlapping areas: ", overlapping.size())
		for area in overlapping:
			print("   - ", area.name, " at ", area.global_position)
			
	# Auto-check every 2 seconds when light is on
	if is_on and Engine.get_frames_drawn() % 120 == 0:  # ~2 seconds at 60fps
		var overlapping = detection_area.get_overlapping_areas()
		if overlapping.size() > 0:
			print("✅ Blue Light detects ", overlapping.size(), " areas automatically")
			for area in overlapping:
				print("   - ", area.name)
