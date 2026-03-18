# MagnifierRegistrar.gd
extends Node

func _ready():
	# Wait a bit for everything to load
	await get_tree().process_frame
	
	print("🔍 MagnifierRegistrar: Searching for MagnifierViewport...")
	
	# Try multiple ways to find the viewport
	var viewport = find_child("MagnifierViewport", true, false)
	
	if not viewport:
		# Try searching from root
		viewport = get_tree().root.find_child("MagnifierViewport", true, false)
	
	if not viewport:
		# Try by path (adjust if your viewport is elsewhere)
		viewport = $"../MagnifierViewport"
	
	if viewport:
		MagnifierManager.register_magnifier_viewport(viewport)
		print("✅ MagnifierViewport registered: ", viewport.name)
		print("   Path: ", viewport.get_path())
	else:
		print("❌ Could not find MagnifierViewport anywhere!")
		print("   Please check that the node exists in your World scene")
