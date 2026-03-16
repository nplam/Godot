# BlueLight_ULTIMATE.gd
extends Area3D

var is_on: bool = false
var visual_light: SpotLight3D = null
var glasses_overlay = null
var initialized: bool = false

func _init():
	print("\n🔵🔵🔵 ULTIMATE: _init()")
	print("   Node: ", name)
	print("   Path: ", get_path())
	print("   Is inside tree: ", is_inside_tree())

func _enter_tree():
	print("\n🔵🔵🔵 ULTIMATE: _enter_tree()")
	print("   Parent: ", get_parent())
	print("   Is inside tree: ", is_inside_tree())
	try_initialize("from _enter_tree")

func _ready():
	print("\n🔵🔵🔵 ULTIMATE: _ready()")
	print("   Parent: ", get_parent())
	print("   Is inside tree: ", is_inside_tree())
	try_initialize("from _ready")

func try_initialize(source: String):
	print("\n🔵🔵🔵 ULTIMATE: try_initialize called ", source)
	print("   initialized flag: ", initialized)
	print("   get_tree(): ", get_tree())
	
	if initialized:
		print("   Already initialized - returning")
		return
	
	print("   Starting initialization...")
	initialized = true
	
	# Get parent
	var parent = get_parent()
	print("   Parent: ", parent)
	
	if not parent:
		print("   ❌ No parent - will try again later")
		initialized = false
		return
	
	print("   ✅ Parent found: ", parent.name)
	print("   Parent children:")
	for child in parent.get_children():
		print("      - ", child.name, " (", child.get_class(), ")")
	
	# Find BlueLight visual node
	print("   Searching for BlueLight node...")
	for child in parent.get_children():
		if child.name == "BlueLight":
			print("      ✅ Found BlueLight node")
			if child is SpotLight3D:
				visual_light = child
				print("      ✅ It's a SpotLight3D")
				visual_light.visible = false
			else:
				print("      ❌ Not a SpotLight3D (it's ", child.get_class(), ")")
			break
	
	if not visual_light:
		print("   ⚠️ BlueLight node not found")
	
	# Find glasses overlay
	print("   Looking for glasses overlay...")
	if get_tree():
		print("      get_tree() OK")
		glasses_overlay = get_tree().root.find_child("OrangeGlassesOverlay", true, false)
		print("      Glasses overlay: ", glasses_overlay)
	else:
		print("      ❌ get_tree() is null")
	
	# Connect signals
	print("   Connecting area_entered signal")
	area_entered.connect(_on_area_entered)
	
	monitoring = false
	print("🔵🔵🔵 INITIALIZATION COMPLETE\n")

func set_active(active: bool):
	print("\n🔵🔵🔵 ULTIMATE: set_active(", active, ")")
	print("   initialized: ", initialized)
	print("   visual_light: ", visual_light)
	
	# ADD THIS LINE
	debug_node_hierarchy()
	
	if not initialized:
		print("   Initialization not done - trying now")
		try_initialize("from set_active")
	
	is_on = active
	if visual_light:
		visual_light.visible = active
		print("   ✅ Set visual light to ", active)
	else:
		print("   ⚠️ visual_light still null")
		print("   Will try to find it again...")
		# Try to find it again
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child.name == "BlueLight" and child is SpotLight3D:
					visual_light = child
					visual_light.visible = active
					print("   ✅ Found on second attempt!")
					break
	
	monitoring = active
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
		
func debug_node_hierarchy():
	print("\n=== NODE HIERARCHY DEBUG ===")
	var parent = get_parent()
	if not parent:
		print("❌ No parent!")
		return
	
	print("Parent (Hand) name: ", parent.name)
	print("Parent children:")
	for i in range(parent.get_child_count()):
		var child = parent.get_child(i)
		print("  [", i, "] ", child.name, " (", child.get_class(), ")")
		
		# Extra info for any node named BlueLight
		if child.name == "BlueLight":
			print("    >>> This is our target! <<<")
			print("    Is SpotLight3D? ", child is SpotLight3D)
			print("    Visible: ", child.visible)
			print("    Path: ", child.get_path())
	
	print("=== END DEBUG ===\n")
	
