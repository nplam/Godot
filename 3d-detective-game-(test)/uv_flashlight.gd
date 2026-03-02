extends SpotLight3D  # Attached to UVFlashlight

@onready var beam = $"../BeamMesh"  # Reference to sibling BeamMesh (under same Camera)
var is_on := false

# Load the UV beam material
var uv_beam_material = preload("res://Materials/uv_beam_material_fixed.tres")

func _ready():
	print("🔦 UV Flashlight ready - press F to toggle")
	
	# Configure the light
	spot_range = 15.0
	spot_angle = 60.0
	light_energy = 0  # Start off
	light_color = Color(0, 1, 1)  # Cyan
	
	# CRITICAL: Only affect Layer 2 (hidden evidence)
	light_cull_mask = 1 << 1  # This sets it to Layer 2 only
	# Debug to verify
	print("Light cull mask: ", light_cull_mask)
	print("Affects Layer 1? ", (light_cull_mask & 1) != 0)  # Should be false
	print("Affects Layer 2? ", (light_cull_mask & (1 << 1)) != 0)  # Should be true
	
	# Configure beam
	if beam:
		# Apply material
		if uv_beam_material:
			beam.material_override = uv_beam_material
			print("✅ UV beam material loaded")
		else:
			print("❌ Failed to load UV beam material")
		
		beam.visible = false  # Start hidden
		print("✅ Beam mesh found at: ", beam.position)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		toggle_uv()

func toggle_uv():
	is_on = !is_on
	print("🔦 UV Light: ", "ON" if is_on else "OFF")
	
	if is_on:
		# Use lower energy to avoid overwhelming the scene
		light_energy = 2.0  # Reduced from 5.0
		if beam:
			beam.visible = true
	else:
		light_energy = 0.0
		if beam:
			beam.visible = false

func _process(delta):
	 # Print cull mask every 60 frames (about once per second)
	if Engine.get_frames_drawn() % 60 == 0:
		print("Current light cull mask: ", light_cull_mask)
		print("  Affects Layer 1? ", (light_cull_mask & 1) != 0)
		print("  Affects Layer 2? ", (light_cull_mask & (1 << 1)) != 0)
	if is_on:
		# Raycast to detect hidden evidence
		var space = get_world_3d().direct_space_state
		var from = global_position
		var to = from + -global_transform.basis.z * spot_range
		
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 2  # Only Layer 2
		var result = space.intersect_ray(query)
		
		if result:
			# Optional: Uncomment to see when you find evidence
			# print("🔍 UV light detected: ", result.collider.name)
			pass
