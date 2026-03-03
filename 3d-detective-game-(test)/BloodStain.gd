# BloodStain.gd
extends Area3D

@export var stain_name: String = "Blood Stain"
@export var stain_description: String = "A suspicious red stain that glows under UV light."
@export var evidence_id: String = "blood_1"
@export var glow_color: Color = Color(1, 0, 0)  # Red glow
@export var glow_intensity: float = 5.0

# References
@onready var mesh_instance: MeshInstance3D = $HiddenBloodStain
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# State tracking
var is_glowing: bool = false
var original_material: Material
var is_collected: bool = false

func _ready():
	# Add to group for detection
	add_to_group("blood_stain")
	
	# Store original material (if any)
	if mesh_instance:
		original_material = mesh_instance.material_override
		# Start invisible
		mesh_instance.visible = false
	else:
		print("⚠️ No MeshInstance3D found in blood stain")
	
	print("🩸 Blood stain ready (invisible): ", stain_name)

# Called by UV light when detected
func on_uv_detected():
	if is_collected or is_glowing:
		return
	
	is_glowing = true
	print("🩸 Blood stain REVEALED: ", stain_name)
	
	# Make visible and apply glow
	mesh_instance.visible = true
	
	# Create glow material
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = glow_color
	glow_mat.emission_enabled = true
	glow_mat.emission = glow_color
	glow_mat.emission_energy_multiplier = glow_intensity
	
	# Apply glow
	mesh_instance.material_override = glow_mat
	
	# Optional: Add a subtle pulsing effect
	create_glow_animation()

func create_glow_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.1, 0.5)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale, 0.5)

# Called by player when interacting with glowing stain
func collect_evidence():
	if is_collected:
		return
	
	is_collected = true
	print("✅ Collecting blood stain: ", stain_name)
	
	# Pass a Dictionary to EvidenceSystem
	var data = {
		"id": evidence_id,
		"name": stain_name,
		"description": stain_description
	}
	EvidenceSystem.collect_evidence(data)
	
	queue_free()

# Reset when UV light moves away
func reset_glow():
	if not is_glowing:
		return
	is_glowing = false
	print("🩸 Blood stain hidden again: ", stain_name)
	
	# Hide and restore original material
	mesh_instance.visible = false
	mesh_instance.material_override = original_material
	
	# Stop any animations
	var tween = get_tree().create_tween()
	tween.kill()
