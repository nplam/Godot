# NewFingerprint.gd
extends Area3D

@export var print_name: String = "Test Fingerprint"
@export var evidence_id: String = "fp_test_2"
@export var evidence_description: String = "A fresh test fingerprint."

func _ready():
	add_to_group("fingerprint_surface")
	collision_layer = 5
	print("\n=== NEW FINGERPRINT CREATED ===")
	print("Name: ", print_name)
	print("Node: ", name)
	print("Path: ", get_path())
	print("Group: ", get_groups())
	print("Layer: ", collision_layer)
	print("Position: ", global_position)
	print("Has MeshInstance3D: ", $MeshInstance3D != null)
	print("Has CollisionShape3D: ", $CollisionShape3D != null)
	if $CollisionShape3D and $CollisionShape3D.shape:
		print("Collision size: ", $CollisionShape3D.shape.size)
	print("=== END FINGERPRINT ===\n")

func on_blue_light_detected():
	print("\n✨✨✨ FINGERPRINT DETECTED! ✨✨✨")
	print("   Name: ", print_name)
	print("   Time: ", Time.get_time_string_from_system())
	
	# Visual feedback - turn bright orange
	if $MeshInstance3D:
		print("   Applying orange material")
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.5, 0.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5, 0.0)
		$MeshInstance3D.material_override = mat
		print("   Material applied")
	else:
		print("   ❌ No MeshInstance3D found!")
	print("=== END DETECTION ===\n")

func collect_evidence():
	var data = {
		"id": evidence_id,
		"name": print_name,
		"description": evidence_description
	}
	EvidenceSystem.collect_evidence(data)
	queue_free()
