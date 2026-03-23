# DebugPlayerScene.gd - Attach to any node or run in console
extends Node

func _ready():
	# Wait a frame to ensure everything is loaded
	await get_tree().process_frame
	
	print("\n" + "=".repeat(60))
	print("🎮 PLAYER SCENE STRUCTURE")
	print("=".repeat(60))
	
	# Find the player node
	var player = get_tree().root.find_child("Player", true, false)
	
	if player:
		print("✅ Player found at: ", player.get_path())
		print("\n📁 Player Hierarchy:\n")
		_print_node_tree(player, 0)
	else:
		print("❌ Player not found! Looking for other nodes...")
		_print_all_nodes()

func _print_node_tree(node: Node, indent_level: int):
	var indent = ""
	for i in range(indent_level):
		indent += "  "
	
	# Get node type
	var node_type = node.get_class()
	
	# Add icon based on type
	var icon = "📁"
	if node_type == "CharacterBody3D":
		icon = "🏃"
	elif node_type == "Camera3D":
		icon = "📷"
	elif node_type == "RayCast3D":
		icon = "🔫"
	elif node_type == "Area3D":
		icon = "🔵"
	elif node_type == "SpotLight3D":
		icon = "💡"
	elif node_type == "MeshInstance3D":
		icon = "🔲"
	elif node_type == "CollisionShape3D":
		icon = "⬛"
	
	print(indent + icon + " " + node.name + " (" + node_type + ")")
	
	# Print important properties for specific nodes
	if node_type == "CharacterBody3D":
		print(indent + "   📍 Position: ", node.position)
		print(indent + "   🏃 Velocity: ", node.velocity)
	elif node_type == "Camera3D":
		print(indent + "   📐 FOV: ", node.fov)
		print(indent + "   🎯 Current: ", node.current)
	elif node_type == "RayCast3D":
		print(indent + "   🎯 Enabled: ", node.enabled)
		print(indent + "   🎯 Colliding: ", node.is_colliding())
	elif node_type == "Area3D":
		print(indent + "   🔵 Monitoring: ", node.monitoring)
		print(indent + "   🔵 Collision Layer: ", node.collision_layer)
	
	# Print script if attached
	if node.get_script():
		print(indent + "   📜 Script: ", node.get_script().get_path())
	
	# Recursively print children
	for child in node.get_children():
		_print_node_tree(child, indent_level + 1)

func _print_all_nodes():
	"""Print all nodes in the scene if player not found"""
	print("\n🔍 Searching entire scene...\n")
	
	var root = get_tree().root
	
	for child in root.get_children():
		print("📁 ", child.name, " (", child.get_class(), ")")
		
		# Look for Player in children
		var player = child.find_child("Player", true, false)
		if player:
			print("   ✅ Found Player under: ", child.name)
			_print_node_tree(player, 1)
