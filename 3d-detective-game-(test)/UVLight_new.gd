# UVLight_new.gd - Complete version with robust node finding
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
	
	# Start disabled
	if visual_light:
		visual_light.visible = false
	monitoring = false
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	print("🔦 UV Light ready")

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
	var overlapping = get_overlapping_areas()
	for area in overlapping:
		if area.has_method("reset_glow"):
			print("   Resetting glow for: ", area.name)
			area.reset_glow()

func _on_area_entered(area: Area3D):
	print("🔦 Area entered: ", area.name)
	
	if not is_on:
		print("   Light off - ignoring")
		return
	
	if area.is_in_group("blood_stain") and area.has_method("on_uv_detected"):
		print("   ✅ Blood stain detected!")
		area.on_uv_detected()
	
	elif area.is_in_group("shoeprint") and area.has_method("on_uv_detected"):
		print("   ✅ Shoeprint detected!")
		area.on_uv_detected()

func _on_area_exited(area: Area3D):
	print("🔦 Area exited: ", area.name)
	
	if area.has_method("reset_glow"):
		print("   Resetting glow for: ", area.name)
		area.reset_glow()
