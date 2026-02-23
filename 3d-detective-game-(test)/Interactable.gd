extends StaticBody3D

@export var object_name: String = "Object"
@export_multiline var examination_text: String = "You see nothing special."
@export var is_evidence: bool = false
@export var evidence_id: String = ""
@export var highlight_color: Color = Color.YELLOW
@export var evidence_texture: Texture2D

var original_material: Material
var highlight_material: Material
var is_focused: bool = false

func _ready():
	# Find the first MeshInstance3D child
	var mesh_instance = find_child("*MeshInstance3D*", true, false)
	if mesh_instance:
		original_material = mesh_instance.material_override
		# Create a simple highlight material (emissive)
		highlight_material = StandardMaterial3D.new()
		highlight_material.emission_enabled = true
		highlight_material.emission = highlight_color

func get_interaction_text() -> String:
	return "Examine " + object_name

func on_focus():
	if is_focused:
		return
	is_focused = true
	var mesh_instance = find_child("*MeshInstance3D*", true, false)
	if mesh_instance:
		mesh_instance.material_override = highlight_material

func on_unfocus():
	if not is_focused:
		return
	is_focused = false
	var mesh_instance = find_child("*MeshInstance3D*", true, false)
	if mesh_instance:
		mesh_instance.material_override = original_material

func interact():
	print("🔥 interact() FIRED for: ", object_name)  # Add this at the VERY top
	inspect()  # <-- ADD THIS LINE
	#if is_evidence:
	#	collect_evidence()
	#else:
	#	show_examination()

func collect_evidence():
	EvidenceSystem.collect_evidence(evidence_id, object_name, examination_text, evidence_texture)
	queue_free()	

func show_examination():
	print("Examination: ", examination_text)

func inspect():
	print("4️⃣ inspect() STARTED for: ", object_name)
	
	# Try to find InspectionView
	var inspection_view = get_tree().current_scene.find_child("InspectionView", true, false)
	print("5️⃣ find_child result: ", inspection_view)
	
	if inspection_view:
		print("6️⃣ ✅ Found InspectionView, calling inspect method...")
		inspection_view.inspect(self, Callable(self, "collect_evidence"), Callable(self, "cancel_inspect"))
		print("7️⃣ inspect() method called on InspectionView")
	else:
		print("6️⃣ ❌ Could NOT find InspectionView!")
		
		# Let's see what's in the scene
		print("7️⃣ Current scene children:")
		var root = get_tree().current_scene
		for child in root.get_children():
			print("   - ", child.name)
			# If there's a UI node, check its children
			if child.name == "UI" or child is CanvasLayer:
				for ui_child in child.get_children():
					print("      └─ ", ui_child.name)
