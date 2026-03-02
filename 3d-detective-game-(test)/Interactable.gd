extends StaticBody3D

@export var object_name: String = "Object"
@export_multiline var examination_text: String = "You see nothing special."
@export var is_evidence: bool = true
@export var evidence_id: String = ""
@export var highlight_color: Color = Color.YELLOW
@export var evidence_texture: Texture2D

var original_material: Material
var highlight_material: Material
var is_focused: bool = false
var is_collected: bool = false
var mesh_instance: MeshInstance3D = null

func _ready():
	# Add to group for easy finding
	add_to_group("evidence_objects")
	
	# Method 1: Find by class (most reliable)
	var meshes = find_children("*", "MeshInstance3D", true, false)
	print("🔍 Found ", meshes.size(), " MeshInstance3D nodes")
	
	if meshes.size() > 0:
		mesh_instance = meshes[0]
		print("   ✅ Using mesh: ", mesh_instance.name)
		original_material = mesh_instance.material_override
		
		# Create highlight material
		highlight_material = StandardMaterial3D.new()
		highlight_material.emission_enabled = true
		highlight_material.emission = highlight_color
		highlight_material.emission_energy_multiplier = 3.0
		print("   ✅ Highlight material created")
	else:
		# Method 2: Look for any node that might be a mesh
		print("⚠️ No MeshInstance3D found, searching all children...")
		list_all_children(self, 0)
		
		# Method 3: Try to find by common mesh names
		var possible_mesh_names = ["Can_A", "Barrel_A", "vase", "mesh", "model", "object"]
		for name in possible_mesh_names:
			var node = find_child(name, true, false)
			if node:
				print("   ✅ Found node with name '", name, "': ", node.name)
				if node is MeshInstance3D:
					mesh_instance = node
					print("   ✅ It is a MeshInstance3D!")
					break
				else:
					print("   ❌ Node is ", node.get_class(), ", not MeshInstance3D")

func list_all_children(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	for child in node.get_children():
		print(indent + child.name + " (" + child.get_class() + ")")
		list_all_children(child, depth + 1)

func get_interaction_text() -> String:
	if is_collected:
		return "Already Collected"
	return "Examine " + object_name

func on_focus():
	print("🎯 on_focus called for: ", object_name)
	print("   is_focused: ", is_focused)
	print("   is_collected: ", is_collected)
	print("   mesh_instance: ", mesh_instance)
	
	if is_focused or is_collected:
		print("   ❌ Cannot focus - already focused or collected")
		return
	
	is_focused = true
	
	if mesh_instance and highlight_material:
		print("   ✅ Applying highlight material")
		mesh_instance.material_override = highlight_material
	else:
		print("   ❌ mesh_instance or highlight_material is null")

func on_unfocus():
	print("🎯 on_unfocus called for: ", object_name)
	print("   is_focused: ", is_focused)
	
	if not is_focused:
		print("   ❌ Not focused, ignoring")
		return
	
	is_focused = false
	
	if mesh_instance:
		print("   ✅ Restoring original material")
		mesh_instance.material_override = original_material
	else:
		print("   ❌ mesh_instance is null")

func interact():
	if is_collected:
		print("⛔ Already collected: ", object_name)
		return
	print("🔥 interact() FIRED for: ", object_name)
	inspect()

func collect_evidence():
	if is_collected:
		return
	
	print("✅ Collecting evidence: ", object_name)
	print("   Texture: ", evidence_texture)
	if evidence_texture:
		print("   Texture size: ", evidence_texture.get_size())
	
	# Create evidence data as Dictionary
	var evidence_data = {
		"id": evidence_id,
		"name": object_name,
		"description": examination_text,
		"icon": evidence_texture,
		"world_object": self
	}
	
	# Store in system
	EvidenceSystem.collect_evidence(evidence_data)
	
	# Mark as collected and disable interaction
	set_collected(true)

func set_collected(collected: bool):
	is_collected = collected
	print("🔄 Setting collected state for ", object_name, " to: ", collected)
	
	if collected:
		# Disable interaction
		collision_layer = 0
		collision_mask = 0
		
		# Visual feedback - make semi-transparent
		if mesh_instance:
			var transparent_mat = StandardMaterial3D.new()
			transparent_mat.albedo_color = Color(1, 1, 1, 0.3)
			transparent_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_instance.material_override = transparent_mat
			print("   ✅ Applied transparent material")
	else:
		# Re-enable interaction
		collision_layer = 1
		collision_mask = 1
		
		# Restore normal appearance
		if mesh_instance:
			mesh_instance.material_override = original_material
			print("   ✅ Restored original material")

func remove_from_inventory():
	# Called when evidence is removed from UI
	print("🗑️ remove_from_inventory called for: ", object_name)
	set_collected(false)
	print("🔄 Object ", object_name, " returned to world")

func inspect():
	print("4️⃣ inspect() STARTED for: ", object_name)
	
	var inspection_view = get_tree().current_scene.find_child("InspectionView", true, false)
	if inspection_view:
		inspection_view.inspect(self, Callable(self, "collect_evidence"), Callable(self, "cancel_inspect"))
	else:
		print("❌ InspectionView not found!")

func cancel_inspect():
	print("❌ Inspection cancelled for: ", object_name)

func get_evidence_id() -> String:
	return evidence_id
