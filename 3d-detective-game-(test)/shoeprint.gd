# Shoeprint.gd
extends Area3D

@export var print_name: String = "Shoeprint"
@export var evidence_id: String = "shoe_1"
@export var evidence_description: String = "A muddy shoeprint that glows under UV light."
@export var glow_color: Color = Color(0.0, 1.0, 0.0)  # Green glow
@export var glow_intensity: float = 3.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var is_glowing: bool = false
var original_material: Material
var is_collected: bool = false

func _ready():
	# Add to group for UV detection
	add_to_group("shoeprint")
	
	# Set collision layer for UV light detection
	collision_layer = 4  # Same layer as blood stains
	
	# Store original material and start invisible
	if mesh_instance:
		original_material = mesh_instance.material_override
		mesh_instance.visible = false
	else:
		print("⚠️ No MeshInstance3D found in shoeprint")
	
	print("👣 Shoeprint ready (invisible): ", print_name)

# Called by UV light when detected
func on_uv_detected():
	if is_collected or is_glowing:
		return
	
	is_glowing = true
	print("👣 Shoeprint REVEALED: ", print_name)
	
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

# Called by player when interacting with glowing print
func collect_evidence():
	if is_collected:
		return
	
	is_collected = true
	print("✅ Collecting shoeprint: ", print_name)
	
	var data = {
		"id": evidence_id,
		"name": print_name,
		"description": evidence_description
	}
	EvidenceSystem.collect_evidence(data)
	
	queue_free()

# Reset when UV light moves away
func reset_glow():
	if not is_glowing:
		return
	is_glowing = false
	print("👣 Shoeprint hidden again: ", print_name)
	
	mesh_instance.visible = false
	mesh_instance.material_override = original_material
