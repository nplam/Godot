extends StaticBody3D

func _ready():
	print("🔍 Searching for meshes under: ", name)
	
	# First, let's see what nodes we have
	print("📁 Children of this node:")
	for child in get_children():
		print("   - ", child.name, " (", child.get_class(), ")")
	
	# Now search recursively for any MeshInstance3D
	var meshes = find_children("*", "MeshInstance3D", true, false)
	print("🔍 Found ", meshes.size(), " MeshInstance3D(s)")
	
	if meshes.size() == 0:
		print("❌ No MeshInstance3D found!")
		return
	
	# Use the first mesh found
	var mesh = meshes[0]
	print("✅ Using mesh: ", mesh.name)
	
	if not mesh.mesh:
		print("❌ Mesh has no mesh data!")
		return
	
	# Get the mesh's bounding box
	var aabb = mesh.mesh.get_aabb()
	
	# Get the mesh's position relative to this StaticBody3D
	var mesh_local_pos = mesh.position
	
	# Calculate the visual center relative to the mesh
	var mesh_visual_center_local = mesh_local_pos + aabb.get_center()
	
	print("\n📊 MESH INFO:")
	print("   Mesh name: ", mesh.name)
	print("   Mesh class: ", mesh.get_class())
	print("   Mesh position relative to StaticBody: ", mesh_local_pos)
	print("   Mesh AABB: ", aabb)
	print("   Mesh visual center (relative to StaticBody): ", mesh_visual_center_local)
	print("   Current StaticBody3D position (global): ", global_position)
	
	print("\n👉 OFFSET NEEDED (move StaticBody3D by):")
	print("   X: ", mesh_visual_center_local.x)
	print("   Y: ", mesh_visual_center_local.y)
	print("   Z: ", mesh_visual_center_local.z)
	
	# Add a visual marker at the visual center
	var marker = MeshInstance3D.new()
	marker.mesh = SphereMesh.new()
	marker.scale = Vector3(0.1, 0.1, 0.1)
	var marker_mat = StandardMaterial3D.new()
	marker_mat.albedo_color = Color.RED
	marker_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = marker_mat
	marker.position = mesh_visual_center_local
	add_child(marker)
	print("✅ Added red sphere at visual center")
