extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002
@export var gravity := 9.8
@export var hand_rotation_speed: float = 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hand: Node3D = $Hand
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var fingerprint_brush: Node3D = $Hand/FingerprintBrush

@export var interaction_ui: CanvasLayer

var current_interactable: Node = null
var current_speed: float
var hand_target_position: Vector3  # For brush physics movement

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current_speed = walk_speed
	interaction_ray.debug_shape_custom_color = Color.RED
	interaction_ray.debug_shape_thickness = 2
	# UV light is now controlled by its own script on the Hand node

func _input(event):
	# MOUSE LOOK: Only when right mouse button is held
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# Rotate entire player left/right (Y-axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate camera up/down (X-axis)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.4, 1.4)
	
	# ESC key to toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# LEFT CLICK to interact with clues
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_interactable:
			print("🖱️ Left click on: ", current_interactable.name)
			CursorManager.set_cursor(CursorManager.CursorState.CLICK)
			current_interactable.interact()
			await get_tree().create_timer(0.1).timeout
			if current_interactable:
				CursorManager.set_cursor(CursorManager.CursorState.HOVER)
			else:
				CursorManager.reset_cursor()
	
	# Toggle fingerprint brush with B key
	if event.is_action_pressed("toggle_brush"):
		if fingerprint_brush:
			print("🖌️ Toggle brush called")
			fingerprint_brush.toggle_active()
		else:
			print("❌ fingerprint_brush is null!")

func _physics_process(delta):
	# Sprint
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = walk_speed

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	
	# Create a basis from just the player's Y rotation (horizontal plane only)
	var player_basis = Basis()
	player_basis = player_basis.rotated(Vector3.UP, rotation.y)
	
	# Convert input to world space using player's horizontal rotation only
	var direction = (player_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()
	
func _process(delta):
	check_interaction()
	rotate_hand_toward_camera(delta)
	
	# Calculate hand target position and move brush if active
	hand_target_position = camera.global_position + camera.global_transform.basis * Vector3(0.2, -0.2, 0.3)
	move_brush_to_hand_target(hand_target_position, delta)

func rotate_hand_toward_camera(delta):
	var target_x_rotation = camera.rotation.x
	hand.rotation.x = lerp(hand.rotation.x, target_x_rotation, hand_rotation_speed * delta)

func check_interaction():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		
		if collider and collider.has_method("get_interaction_text"):
			CursorManager.set_cursor(CursorManager.CursorState.HOVER)
			
			if current_interactable != collider:
				# Unfocus previous
				if current_interactable and current_interactable.has_method("on_unfocus"):
					current_interactable.on_unfocus()
				
				# Focus new
				current_interactable = collider
				if current_interactable.has_method("on_focus"):
					current_interactable.on_focus()
				
				# Show the UI prompt
				interaction_ui.show_prompt(collider.get_interaction_text())
			return
	
	# Not looking at any interactable
	if current_interactable:
		if current_interactable.has_method("on_unfocus"):
			current_interactable.on_unfocus()
		current_interactable = null
	
	interaction_ui.hide_prompt()
	CursorManager.reset_cursor()

# Function to move brush with physics (to prevent clipping)
func move_brush_to_hand_target(target_pos: Vector3, delta):
	if fingerprint_brush and fingerprint_brush.has_method("toggle_active") and fingerprint_brush.is_active:
		var direction = (target_pos - fingerprint_brush.global_position).normalized()
		var distance = target_pos.distance_to(fingerprint_brush.global_position)
		var speed = min(distance * 10.0, 20.0)  # Speed based on distance
		fingerprint_brush.linear_velocity = direction * speed
