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
	# Debug initial state
	print("\n=== BLOOD STAIN READY ===")
	print("Name: ", stain_name)
	print("Node: ", name)
	print("Path: ", get_path())
	
	# Add to group for detection
	add_to_group("blood_stain")
	print("Groups after adding: ", get_groups())
	
	# Set collision layer for UV light detection
	collision_layer = 4  # Blood stains layer
	# Force layer bits
	set_collision_layer_value(4, true)
	set_collision_layer_value(3, false)  # Explicitly turn off layer 3
	print("Collision Layer set to: ", collision_layer)
	
	# Verify layer bits
	var layers = []
	for i in range(1, 6):
		if get_collision_layer_value(i):
			layers.append(str(i))
	print("Active Layers: ", "Layer " + ", Layer ".join(layers) if layers else "None")
	
	# Store original material (if any)
	if mesh_instance:
		original_material = mesh_instance.material_override
		# Start invisible
		mesh_instance.visible = false
		print("Mesh instance found: ", mesh_instance.name)
		print("Mesh visible: ", mesh_instance.visible)
	else:
		print("⚠️ No MeshInstance3D found in blood stain")
	
	# Check collision shape
	if collision_shape:
		print("CollisionShape3D found")
		print("   Position: ", collision_shape.position)
		print("   Scale: ", collision_shape.scale)
		print("   Disabled: ", collision_shape.disabled)
		if collision_shape.shape:
			print("   Shape type: ", collision_shape.shape.get_class())
			if collision_shape.shape is BoxShape3D:
				print("   Shape size: ", collision_shape.shape.size)
		else:
			print("   ⚠️ No shape assigned!")
	else:
		print("⚠️ No CollisionShape3D found!")
	
	print("=== END BLOOD STAIN READY ===\n")

# Called by UV light when detected
func on_uv_detected():
	print("\n🩸 on_uv_detected() CALLED for: ", stain_name)
	print("   is_collected: ", is_collected)
	print("   is_glowing: ", is_glowing)
	
	if is_collected or is_glowing:
		print("   Already glowing or collected - ignoring")
		return
	
	is_glowing = true
	print("🩸 Blood stain REVEALED: ", stain_name)
	
	# Make visible and apply glow
	if mesh_instance:
		mesh_instance.visible = true
		print("   Mesh visibility set to: ", mesh_instance.visible)
	else:
		print("   ⚠️ No mesh instance to show!")
	
	# Create glow material
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = glow_color
	glow_mat.emission_enabled = true
	glow_mat.emission = glow_color
	glow_mat.emission_energy_multiplier = glow_intensity
	
	# Apply glow
	if mesh_instance:
		mesh_instance.material_override = glow_mat
		print("   Glow material applied")
	
	# Optional: Add a subtle pulsing effect
	create_glow_animation()
	print("=== END on_uv_detected ===\n")

func create_glow_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.1, 0.5)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale, 0.5)

# Called by player when interacting with glowing stain
func collect_evidence():
	print("\n💰 collect_evidence() CALLED for: ", stain_name)
	if is_collected:
		print("   Already collected - ignoring")
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
	print("   Evidence system called with ID: ", evidence_id)
	
	queue_free()
	print("   Blood stain removed from scene")
	print("=== END collect_evidence ===\n")

# Reset when UV light moves away
func reset_glow():
	print("\n🔄 reset_glow() CALLED for: ", stain_name)
	if not is_glowing:
		print("   Not glowing - ignoring")
		return
	is_glowing = false
	print("🩸 Blood stain hidden again: ", stain_name)
	
	# Hide and restore original material
	if mesh_instance:
		mesh_instance.visible = false
		mesh_instance.material_override = original_material
		print("   Mesh hidden and material restored")
	
	# Stop any animations
	var tween = get_tree().create_tween()
	tween.kill()
	print("=== END reset_glow ===\n")
