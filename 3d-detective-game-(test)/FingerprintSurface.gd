# FingerprintSurface.gd - Updated with interaction methods for player detection
extends StaticBody3D

@export var print_name: String = "Fingerprint"
@export var evidence_id: String = "fingerprint_1"
@export var evidence_type: int = 1  # 1 = FINGERPRINT
@export var match_value: String = "fp_001"  # Matches suspect's fingerprint_id
@export var evidence_description: String = "A latent fingerprint that glows under blue light."
@export var glow_color: Color = Color(1.0, 0.5, 0.0)  # Orange glow
@export var glow_intensity: float = 0.8
@export var evidence_texture: Texture2D  # Optional: fingerprint texture

# References
@onready var mesh_instance: MeshInstance3D = $HiddenFingerprint
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# State tracking
var is_glowing: bool = false
var original_material: Material
var is_collected: bool = false
var is_added_to_case: bool = false

# Double-click detection
var last_click_time: float = 0.0
var double_click_threshold: float = 0.3

func _ready():
	print("\n" + "=".repeat(50))
	print("🔍 FINGERPRINT DEBUG - START")
	print("=".repeat(50))
	print("Name: ", print_name)
	print("Node: ", name)
	
	# Add to groups
	add_to_group("fingerprint_surface")
	print("📌 Groups: ", get_groups())
	
	# Make sure raycast can detect this
	input_ray_pickable = true
	print("🎯 input_ray_pickable: ", input_ray_pickable)
	
	# Set collision layer (Layer 5 for fingerprints)
	collision_layer = 5
	set_collision_layer_value(5, true)
	print("🎯 Collision layer 5 enabled: ", get_collision_layer_value(5))
	
	# Mesh setup
	if mesh_instance:
		original_material = mesh_instance.material_override
		mesh_instance.visible = false
		print("✅ Mesh instance found")
	else:
		print("❌ No mesh instance found!")
	
	print("=".repeat(50) + "\n")

# Called by player.gd to get the text to display
func get_interaction_text() -> String:
	return "Examine " + print_name

# Called when player looks at it
func on_focus():
	# Optional: Add highlight effect
	pass

# Called when player stops looking at it
func on_unfocus():
	# Optional: Remove highlight effect
	pass

# Called by player.gd when clicking
func interact():
	print("\n🖱️ interact() called on fingerprint: ", print_name)
	print("   is_glowing: ", is_glowing)
	print("   is_collected: ", is_collected)
	
	if is_glowing and not is_collected:
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_diff = current_time - last_click_time if last_click_time > 0 else 999
		
		print("   Time since last click: ", time_diff)
		
		if time_diff < double_click_threshold and time_diff > 0.01:
			print("\n📋📋📋 DOUBLE CLICK DETECTED! Adding to case board 📋📋📋")
			add_to_case_board()
		else:
			print("   Single click detected (double-click within ", double_click_threshold, "s to add)")
		
		last_click_time = current_time

func on_blue_light_detected():
	print("\n🔵 on_blue_light_detected() CALLED for: ", print_name)
	print("   is_collected: ", is_collected)
	print("   is_glowing: ", is_glowing)
	
	if is_collected or is_glowing:
		print("   Already glowing or collected - ignoring")
		return
	
	if not mesh_instance:
		print("   ❌ No mesh instance - cannot show fingerprint!")
		return
	
	is_glowing = true
	print("🔵 Fingerprint REVEALED: ", print_name)
	
	mesh_instance.visible = true
	
	var current_mat = mesh_instance.material_override
	if not current_mat:
		current_mat = StandardMaterial3D.new()
		mesh_instance.material_override = current_mat
	
	if original_material and original_material.albedo_texture:
		current_mat.albedo_texture = original_material.albedo_texture
	
	current_mat.emission_enabled = true
	current_mat.emission = glow_color
	current_mat.emission_energy_multiplier = glow_intensity
	current_mat.albedo_color = Color.WHITE
	
	if mesh_instance:
		create_glow_animation()

func create_glow_animation():
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.02, 0.8)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale, 0.8)

func add_to_case_board():
	print("\n📋 add_to_case_board() CALLED")
	print("   print_name: ", print_name)
	print("   evidence_id: ", evidence_id)
	
	if is_added_to_case or is_collected:
		print("   Already added or collected - ignoring")
		return
	
	is_added_to_case = true
	print("📋 Adding to case board: ", print_name)
	
	var data = {
		"id": evidence_id,
		"name": print_name,
		"description": evidence_description,
		"texture": evidence_texture,
		"type": evidence_type,
		"match_value": match_value
	}
	
	var case_board = get_tree().get_first_node_in_group("case_board")
	print("   case_board found: ", case_board)
	
	if case_board and case_board.has_method("add_evidence"):
		case_board.add_evidence(data)
		SoundManager.play_evidence_collect()
		flash_orange()
		print("   ✅ Added to case board!")
	else:
		print("   ⚠️ Case board not found!")

func flash_orange():
	if mesh_instance:
		var original_mat = mesh_instance.material_override
		var flash_mat = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1, 0.8, 0)
		flash_mat.emission_enabled = true
		flash_mat.emission = Color(1, 0.5, 0)
		mesh_instance.material_override = flash_mat
		await get_tree().create_timer(0.2).timeout
		mesh_instance.material_override = original_mat

func collect_evidence():
	print("\n💰 collect_evidence() CALLED for: ", print_name)
	if is_collected:
		print("   Already collected - ignoring")
		return
	
	is_collected = true
	print("✅ Collecting fingerprint: ", print_name)
	
	var data = {
		"id": evidence_id,
		"name": print_name,
		"description": evidence_description,
		"type": evidence_type,
		"match_value": match_value
	}
	EvidenceSystem.collect_evidence(data)
	
	queue_free()

func reset_glow():
	print("\n🔄 reset_glow() CALLED for: ", print_name)
	if not is_glowing:
		print("   Not glowing - ignoring")
		return
	
	is_glowing = false
	print("🔵 Fingerprint hidden again: ", print_name)
	
	if mesh_instance:
		mesh_instance.visible = false
		mesh_instance.material_override = original_material
	
	var tween = get_tree().create_tween()
	tween.kill()
