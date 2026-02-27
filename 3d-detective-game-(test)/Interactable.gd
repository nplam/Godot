extends StaticBody3D

@export var object_name: String = "Object"
@export_multiline var examination_text: String = "You see nothing special."
@export var is_evidence: bool = false
@export var evidence_id: String = ""
@export var highlight_color: Color = Color.YELLOW
@export var evidence_texture: Texture2D

var original_materials = {}
var highlight_material: Material
var is_focused: bool = false

func _ready():
	print("🟢 _ready() called for: ", object_name)
	
	# Create highlight material
	highlight_material = StandardMaterial3D.new()
	highlight_material.emission_enabled = true
	highlight_material.emission = highlight_color
	highlight_material.emission_energy_multiplier = 2.0
	
	# Find and store all meshes
	var mesh_instances = find_children("*", "MeshInstance3D", true, false)
	print("   Found ", mesh_instances.size(), " mesh(es)")
	
	for i in range(mesh_instances.size()):
		var mesh = mesh_instances[i]
		original_materials[mesh] = mesh.material_override
		print("   Mesh ", i, ": ", mesh.name, " | Material: ", mesh.material_override)

func get_interaction_text() -> String:
	return "Examine " + object_name

func on_focus():
	print("🎯 on_focus() called for: ", object_name, " | Current focused: ", is_focused)
	
	if is_focused:
		print("   Already focused, returning")
		return
	
	is_focused = true
	
	var mesh_instances = find_children("*", "MeshInstance3D", true, false)
	print("   Found ", mesh_instances.size(), " meshes to highlight")
	
	for i in range(mesh_instances.size()):
		var mesh = mesh_instances[i]
		print("   Applying highlight to mesh ", i, ": ", mesh.name)
		mesh.material_override = highlight_material

func on_unfocus():
	print("🎯 on_unfocus() called for: ", object_name, " | Current focused: ", is_focused)
	
	if not is_focused:
		print("   Not focused, returning")
		return
	
	is_focused = false
	
	var mesh_instances = find_children("*", "MeshInstance3D", true, false)
	print("   Found ", mesh_instances.size(), " meshes to restore")
	
	for i in range(mesh_instances.size()):
		var mesh = mesh_instances[i]
		if original_materials.has(mesh):
			print("   Restoring mesh ", i, ": ", mesh.name, " to original: ", original_materials[mesh])
			mesh.material_override = original_materials[mesh]
		else:
			print("   ⚠️ No original material for mesh ", i, ": ", mesh.name)
			mesh.material_override = null

func interact():
	print("🔥 interact() FIRED for: ", object_name)
	inspect()

func collect_evidence():
	print("✅ Collecting evidence: ", object_name)
	EvidenceSystem.collect_evidence(evidence_id, object_name, examination_text, evidence_texture)
	queue_free()

func show_examination():
	print("Examination: ", examination_text)

func inspect():
	print("4️⃣ inspect() STARTED for: ", object_name)
	
	var inspection_view = get_tree().current_scene.find_child("InspectionView", true, false)
	if inspection_view:
		inspection_view.inspect(self, Callable(self, "collect_evidence"), Callable(self, "cancel_inspect"))
	else:
		print("❌ InspectionView not found!")

func cancel_inspect():
	print("❌ Inspection cancelled for: ", object_name)
