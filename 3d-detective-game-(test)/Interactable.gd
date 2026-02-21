extends StaticBody3D

@export var object_name: String = "Object"
@export_multiline var examination_text: String = "You see nothing special."
@export var is_evidence: bool = false
@export var evidence_id: String = ""
@export var highlight_color: Color = Color.YELLOW

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
	if is_evidence:
		collect_evidence()
	else:
		show_examination()

func collect_evidence():
	EvidenceSystem.collect_evidence(evidence_id, object_name, examination_text)
	queue_free()	

func show_examination():
	print("Examination: ", examination_text)
