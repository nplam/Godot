# BlueLight_Fresh.gd - Based on working UVLight template
extends Area3D

# References
@onready var visual_light: SpotLight3D = $"../BlueLight"
var is_on: bool = false
var glasses_overlay = null

func _ready():
	print("\n🔵🔵🔵 BLUE LIGHT FRESH INITIALIZING 🔵🔵🔵")
	print("   Node: ", name)
	print("   Path: ", get_path())
	print("   Parent: ", get_parent())
	
	# Find visual light
	visual_light = $"../BlueLight"
	print("   Visual light via $../BlueLight: ", visual_light)
	
	if not visual_light:
		# Try alternative methods
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child.name == "BlueLight" and child is SpotLight3D:
					visual_light = child
					print("   ✅ Found BlueLight via sibling search")
					break
	
	# Find glasses overlay
	glasses_overlay = get_tree().root.find_child("OrangeGlassesOverlay", true, false)
	print("   Glasses overlay: ", glasses_overlay)
	
	# Start disabled
	if visual_light:
		visual_light.visible = false
		print("   Visual light disabled")
	monitoring = false
	print("   Monitoring disabled")
	
	# Connect signals - BOTH entered and exited
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)  # ← CRITICAL: Add this line!
	print("   Signals connected (entered and exited)")
	
	print("🔵 Blue Light Fresh ready\n")

func set_active(active: bool):
	print("\n🔵 set_active(", active, ") called")
	print("   Current visual_light: ", visual_light)
	
	is_on = active
	
	if visual_light:
		visual_light.visible = active
		print("   ✅ Visual light set to ", active)
		print("   Light energy: ", visual_light.light_energy)
		print("   Light range: ", visual_light.spot_range)
		print("   Light cull mask: ", visual_light.light_cull_mask)
	else:
		print("   ⚠️ visual_light is null!")
	
	monitoring = active
	print("   Monitoring set to ", active)
	print("🔵 Blue Light active: ", active)

func _on_area_entered(area: Area3D):
	if not is_on:
		return
	
	var glasses_on = glasses_overlay and glasses_overlay.is_on if glasses_overlay else false
	if not glasses_on:
		return
	
	if area.is_in_group("fingerprint_surface") and area.has_method("on_blue_light_detected"):
		print("🔵 Fingerprint detected!")
		area.on_blue_light_detected()

func _on_area_exited(area: Area3D):
	print("\n🔵 AREA EXITED: ", area.name)
	
	if area.has_method("reset_glow"):
		print("   Calling reset_glow() on: ", area.name)
		area.reset_glow()
