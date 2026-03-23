# UVLight_new.gd - Detects shoeprints AND hair
extends Area3D

# Track light state
var is_on: bool = false
var visual_light: SpotLight3D = null

func _ready():
	print("🔦 UVLight_new attached to: ", name)
	print("   Node type: ", get_class())
	print("   Parent: ", get_parent().name)
	
	# ROBUST NODE FINDING FOR UV LIGHT
	print("   Searching for UVLight node...")
	
	# Method 1: Check siblings directly
	for child in get_parent().get_children():
		if child.name == "UVLight" and child is SpotLight3D:
			visual_light = child
			print("   ✅ Found as direct sibling: ", child.name)
			break
	
	# Method 2: Search recursively
	if not visual_light:
		visual_light = get_parent().find_child("UVLight", true, false)
		if visual_light:
			print("   ✅ Found via find_child: ", visual_light.name)
	
	# Method 3: Search entire tree
	if not visual_light:
		visual_light = get_tree().root.find_child("UVLight", true, false)
		if visual_light:
			print("   ✅ Found via root search: ", visual_light.name)
	
	print("   Final visual light found: ", visual_light != null)
	if visual_light:
		print("   Visual light path: ", visual_light.get_path())
	else:
		print("   ❌ CRITICAL: UVLight node not found anywhere!")
		print("   Parent children: ", get_parent().get_children())
	
	# DEBUG: Print detection area info (this node itself)
	print("\n🔦 UV LIGHT DETECTION AREA:")
	print("   Position: ", global_position)
	print("   Local position: ", position)
	var shape_node = $CollisionShape3D
	if shape_node and shape_node.shape:
		print("   Shape type: ", shape_node.shape.get_class())
		if shape_node.shape is BoxShape3D:
			print("   Box size: ", shape_node.shape.size)
		elif shape_node.shape is CylinderShape3D:
			print("   Cylinder radius: ", shape_node.shape.radius)
			print("   Cylinder height: ", shape_node.shape.height)
	else:
		print("   ⚠️ No collision shape found!")
	
	# Start disabled
	if visual_light:
		visual_light.visible = false
	monitoring = false
	
	# Connect signals for BOTH Area3D and StaticBody3D
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("🔦 UV Light ready (detects shoeprints and hair)\n")

func set_active(active: bool):
	is_on = active
	if visual_light:
		visual_light.visible = active
		print("   UV light visibility set to: ", active)
	else:
		print("   ⚠️ Cannot set visibility - visual_light null!")
	monitoring = active
	print("🔦 UV Light active: ", active)
	
	# When turning off, reset all evidence
	if not active:
		reset_all_evidence()

func reset_all_evidence():
	print("🔄 Resetting all evidence")
	for area in get_overlapping_areas():
		if area.has_method("reset_glow"):
			print("   Resetting glow for area: ", area.name)
			area.reset_glow()
	for body in get_overlapping_bodies():
		if body.has_method("reset_glow"):
			print("   Resetting glow for body: ", body.name)
			body.reset_glow()

# Detect Area3D (like blood stains)
func _on_area_entered(area: Area3D):
	print("\n🔦 AREA ENTERED: ", area.name)
	print("   Area groups: ", area.get_groups())
	
	if not is_on:
		print("   Light off - ignoring")
		return
	
	# Check for blood_stain (shoeprint) OR hair_evidence
	if area.has_method("on_uv_detected"):
		if area.is_in_group("blood_stain"):
			print("   ✅ Blood stain (shoeprint) detected!")
			area.on_uv_detected()
		elif area.is_in_group("hair_evidence"):
			print("   ✅ Hair evidence detected!")
			area.on_uv_detected()
		else:
			print("   ❌ Not a valid evidence type (wrong group)")
	else:
		print("   ❌ No on_uv_detected method")

# Detect StaticBody3D (like shoeprints and hair)
func _on_body_entered(body: Node3D):
	print("\n🔦 BODY ENTERED: ", body.name)
	print("   Body groups: ", body.get_groups())
	
	if not is_on:
		print("   Light off - ignoring")
		return
	
	# Check if body has the detection method
	if body.has_method("on_uv_detected"):
		# Check for any of the evidence groups
		if body.is_in_group("shoeprint"):
			print("   ✅ Shoeprint detected!")
			body.on_uv_detected()
		elif body.is_in_group("blood_stain"):
			print("   ✅ Blood stain (shoeprint) detected!")
			body.on_uv_detected()
		elif body.is_in_group("hair_evidence"):
			print("   ✅ Hair evidence detected!")
			body.on_uv_detected()
		else:
			print("   ❌ Not a valid evidence type (wrong group)")
	else:
		print("   ❌ No on_uv_detected method")

func _on_area_exited(area: Area3D):
	print("\n🔦 AREA EXITED: ", area.name)
	if area.has_method("reset_glow"):
		area.reset_glow()

func _on_body_exited(body: Node3D):
	print("\n🔦 BODY EXITED: ", body.name)
	if body.has_method("reset_glow"):
		body.reset_glow()
