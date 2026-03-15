# FingerprintSurface.gd
extends Area3D

@export var surface_name: String = "Test Surface"
@export var evidence_id: String = "fp_test_1"
@export var evidence_name: String = "Fingerprint"
@export var evidence_description: String = "A latent fingerprint revealed by blue light."
@export var glow_color: Color = Color(1.0, 0.5, 0.0)  # Orange glow

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var is_revealed: bool = false
var original_material: Material
var is_collected: bool = false

func _ready():
	# Add to group for detection
	add_to_group("fingerprint_surface")
	
	# Set collision layer for blue light detection
	collision_layer = 5  # Fingerprint surfaces layer
	
	# Store original material
	if mesh_instance:
		original_material = mesh_instance.material_override
	else:
		print("⚠️ No MeshInstance3D found in fingerprint surface")
	
	print("🔍 Fingerprint surface ready: ", surface_name)

# Called by blue light when detected (requires orange glasses)
func on_blue_light_detected():
	if is_collected or is_revealed:
		return
	
	is_revealed = true
	print("🔵 Fingerprint REVEALED on ", surface_name)
	
	# Create orange glow material
	if mesh_instance:
		var glow_mat = StandardMaterial3D.new()
		glow_mat.emission_enabled = true
		glow_mat.emission = glow_color
		glow_mat.emission_energy_multiplier = 2.0
		glow_mat.albedo_color = glow_color
		mesh_instance.material_override = glow_mat
		
		# Optional: Add subtle pulsing effect
		create_glow_animation()

func create_glow_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.05, 0.8)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale, 0.8)

# Called by player when interacting with revealed fingerprint
func collect_evidence():
	if is_collected:
		return
	
	is_collected = true
	print("✅ Collecting fingerprint evidence: ", surface_name)
	
	var data = {
		"id": evidence_id,
		"name": evidence_name,
		"description": evidence_description
	}
	EvidenceSystem.collect_evidence(data)
	
	queue_free()

# Reset when blue light moves away (optional)
func reset_glow():
	if not is_revealed or is_collected:
		return
	is_revealed = false
	print("👋 Fingerprint hidden again: ", surface_name)
	
	if mesh_instance:
		mesh_instance.material_override = original_material
	
	# Stop animations
	var tween = get_tree().create_tween()
	tween.kill()
