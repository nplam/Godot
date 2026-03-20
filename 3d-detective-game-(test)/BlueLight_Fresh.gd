# BlueLight_Fresh.gd - With full debug
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
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	print("   Signals connected (entered and exited)")
	
	print("🔵 Blue Light Fresh ready\n")

func set_active(active: bool):
	print("\n🔵 set_active(", active, ") called")
	print("   Current visual_light: ", visual_light)
	
	is_on = active
	
	if visual_light:
		visual_light.visible = active
		print("   ✅ Visual light set to ", active)
	else:
		print("   ⚠️ visual_light is null!")
	
	monitoring = active
	print("   Monitoring set to ", active)
	print("🔵 Blue Light active: ", active)

func _on_area_entered(area: Area3D):
	print("\n🔵🔵🔵 AREA ENTERED: ", area.name)
	print("   is_on: ", is_on)
	print("   area groups: ", area.get_groups())
	print("   area has on_blue_light_detected: ", area.has_method("on_blue_light_detected"))
	
	if not is_on:
		print("   ❌ Light is off - ignoring")
		return
	
	var glasses_on = glasses_overlay and glasses_overlay.is_on if glasses_overlay else false
	print("   Glasses on: ", glasses_on)
	
	if not glasses_on:
		print("   👓 Glasses off - fingerprint invisible")
		return
	
	print("   ✅ Glasses on - can detect")
	
	if area.is_in_group("fingerprint_surface") and area.has_method("on_blue_light_detected"):
		print("   ✅✅✅ Fingerprint detected! Calling on_blue_light_detected()")
		area.on_blue_light_detected()
	else:
		print("   ❌ Not a valid fingerprint surface")
		if not area.is_in_group("fingerprint_surface"):
			print("      - Wrong group (should be 'fingerprint_surface')")
		if not area.has_method("on_blue_light_detected"):
			print("      - Missing on_blue_light_detected method")

func _on_area_exited(area: Area3D):
	print("\n🔵 AREA EXITED: ", area.name)
	
	if area.has_method("reset_glow"):
		print("   Calling reset_glow() on: ", area.name)
		area.reset_glow()
