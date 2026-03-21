# Keypad.gd - Complete keypad script for locked door
extends Area3D

@export var door: Node3D  # Link to the Door node in Inspector
@export var correct_code: String = "1234"  # The code to open the door

# State variables
var current_input: String = ""
var is_open: bool = false
var is_locked_out: bool = false
var attempts: int = 0

# Visual elements
@onready var display: Label3D = $KeypadDisplay
@onready var keypad_mesh: MeshInstance3D = $KeypadMesh
@onready var error_sound: AudioStreamPlayer3D = $ErrorSound
@onready var success_sound: AudioStreamPlayer3D = $SuccessSound

# Original material for reset
var original_material: Material

func _ready():
	# Add to interactable group for detection
	add_to_group("interactable")
	
	# FORCE ENABLE COLLISION SHAPE
	var collision_shape = $CollisionShape3D
	if collision_shape:
		collision_shape.disabled = false
		print("🔧 CollisionShape3D FORCED ENABLED")
	else:
		print("❌ CollisionShape3D not found!")
	
	# DEBUG: Print keypad position and collision info
	print("\n=== KEYPAD POSITION DEBUG ===")
	print("Keypad global position: ", global_position)
	print("Keypad local position: ", position)
	print("Keypad scale: ", scale)
	print("Parent: ", get_parent().name)
	
	# Check collision shape
	if collision_shape:
		print("CollisionShape3D exists: true")
		print("  Position: ", collision_shape.position)
		print("  Scale: ", collision_shape.scale)
		print("  Disabled: ", collision_shape.disabled)
		if collision_shape.shape:
			print("  Shape type: ", collision_shape.shape.get_class())
			if collision_shape.shape is BoxShape3D:
				print("  Box size: ", collision_shape.shape.size)
	else:
		print("❌ CollisionShape3D NOT FOUND!")
	print("===========================\n")
	
	# Add a visible red sphere marker to see keypad position
	var marker = MeshInstance3D.new()
	marker.mesh = SphereMesh.new()
	marker.scale = Vector3(0.1, 0.1, 0.1)
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color.RED
	marker.material_override = red_mat
	add_child(marker)
	print("🔴 Added red marker at keypad position")
	
	# Add green box showing collision area
	if collision_shape and collision_shape.shape:
		var debug_box = MeshInstance3D.new()
		debug_box.mesh = BoxMesh.new()
		debug_box.scale = collision_shape.shape.size
		var green_mat = StandardMaterial3D.new()
		green_mat.albedo_color = Color(0, 1, 0, 0.5)  # Semi-transparent green
		green_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debug_box.material_override = green_mat
		debug_box.position = collision_shape.position
		add_child(debug_box)
		print("🟢 Added green debug box showing collision area")
	
	# Store original material
	if keypad_mesh:
		original_material = keypad_mesh.material_override
	
	# Initialize display
	update_display()
	
	print("🔢 Keypad ready - Enter code to open door")
	
	# Check again after a frame to ensure collision is enabled
	await get_tree().process_frame
	if collision_shape:
		print("🔍 After frame - CollisionShape3D disabled: ", collision_shape.disabled)

# Called when player looks at the keypad
func get_interaction_text() -> String:
	print("🔢 get_interaction_text called!")  # This will tell us if keypad is being detected
	if is_open:
		return "Door is open"
	if is_locked_out:
		return "Keypad locked - try later"
	return "Use Keypad"

# Called when player looks at the keypad (focus)
func on_focus():
	if keypad_mesh and not is_locked_out and not is_open:
		var highlight = StandardMaterial3D.new()
		highlight.emission_enabled = true
		highlight.emission = Color.YELLOW
		keypad_mesh.material_override = highlight

# Called when player looks away
func on_unfocus():
	if keypad_mesh:
		keypad_mesh.material_override = original_material

# Called when player presses E
func interact():
	print("🔢 Interact() called!")
	if is_open:
		print("Door already open")
		return
	
	if is_locked_out:
		print("Keypad locked - try later")
		return
	
	print("🔢 Enter code (type numbers, press Enter)")
	print("   Current: ", current_input)

# Handle keyboard input
func _input(event):
	# Only process input if this keypad is focused (player is looking at it)
	if not has_focus():
		return
	
	if is_open or is_locked_out:
		return
	
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		
		# Number keys 0-9
		if key >= KEY_0 and key <= KEY_9:
			var digit = char(key)
			current_input += digit
			update_display()
			print("   Entered: ", current_input)
		
		# Enter key - verify code
		elif key == KEY_ENTER:
			verify_code()
		
		# Backspace - delete last digit
		elif key == KEY_BACKSPACE:
			if current_input.length() > 0:
				current_input = current_input.substr(0, current_input.length() - 1)
				update_display()
				print("   Backspace: ", current_input)

# Update the display text
func update_display():
	if not display:
		return
	
	# Show underscores for empty positions
	var text = current_input
	while text.length() < 4:
		text = "_" + text
	display.text = text

# Verify the entered code
func verify_code():
	if current_input == correct_code:
		success()
	else:
		fail()

# Handle correct code
func success():
	print("✅ Correct code! Door opening...")
	
	# Play success sound
	if success_sound:
		success_sound.play()
	
	# Visual feedback - green flash
	if keypad_mesh:
		var green_mat = StandardMaterial3D.new()
		green_mat.albedo_color = Color.GREEN
		green_mat.emission_enabled = true
		green_mat.emission = Color.GREEN
		keypad_mesh.material_override = green_mat
		await get_tree().create_timer(0.5).timeout
		keypad_mesh.material_override = original_material
	
	# Open the door
	if door and door.has_method("open"):
		door.open()
	else:
		print("⚠️ Door not linked or missing open() method!")
	
	is_open = true

# Handle wrong code
func fail():
	attempts += 1
	print("❌ Wrong code! Attempts: ", attempts)
	
	# Play error sound
	if error_sound:
		error_sound.play()
	
	# Visual feedback - red flash
	if keypad_mesh:
		var red_mat = StandardMaterial3D.new()
		red_mat.albedo_color = Color.RED
		red_mat.emission_enabled = true
		red_mat.emission = Color.RED
		keypad_mesh.material_override = red_mat
		await get_tree().create_timer(0.3).timeout
		keypad_mesh.material_override = original_material
	
	# Clear input
	current_input = ""
	update_display()
	
	# Optional: Lockout after 3 attempts
	if attempts >= 3:
		lockout()

# Lockout after too many wrong attempts
func lockout():
	is_locked_out = true
	print("🔒 Keypad LOCKED for 10 seconds")
	
	# Darken keypad
	if keypad_mesh:
		var dark_mat = StandardMaterial3D.new()
		dark_mat.albedo_color = Color(0.2, 0.2, 0.2)
		keypad_mesh.material_override = dark_mat
	
	# Wait for lockout duration
	await get_tree().create_timer(10.0).timeout
	
	# Reset
	is_locked_out = false
	attempts = 0
	print("🔓 Keypad unlocked")
	if keypad_mesh:
		keypad_mesh.material_override = original_material

# Check if player is looking at this keypad
func has_focus() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("current_interactable"):
		return player.current_interactable == self
	return false
