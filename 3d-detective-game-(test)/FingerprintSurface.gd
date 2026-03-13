# FingerprintSurface.gd
extends Area3D

@export var surface_name: String = "Test Surface"
@export var evidence_id: String = "fp_test_1"
@export var evidence_name: String = "Fingerprint"
@export var evidence_description: String = "A clear fingerprint found on the test surface."

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var is_dusted: bool = false
var original_material: Material

func _ready():
	add_to_group("fingerprint_surface")
	
	if mesh_instance:
		original_material = mesh_instance.material_override
	print("🔍 Fingerprint surface ready: ", surface_name)

func on_brush_dusted():
	if is_dusted:
		return
	
	is_dusted = true
	print("✨ Fingerprint revealed on ", surface_name)
	
	# Visual feedback - white powder effect
	if mesh_instance:
		var powder_mat = StandardMaterial3D.new()
		powder_mat.albedo_color = Color(1, 1, 1, 0.5)  # Semi-transparent white
		mesh_instance.material_override = powder_mat
		
		# Optional: Add a small glow
		powder_mat.emission_enabled = true
		powder_mat.emission = Color(1, 1, 1, 0.3)

func collect_evidence():
	var data = {
		"id": evidence_id,
		"name": evidence_name,
		"description": evidence_description
	}
	EvidenceSystem.collect_evidence(data)
	queue_free()
