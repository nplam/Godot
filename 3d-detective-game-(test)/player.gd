extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002
@export var gravity := 9.8

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

@export var interaction_ui: CanvasLayer   # drag the UI node here in inspector
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay

var current_interactable: Node = null
var current_speed: float

func _ready():
	# Start with visible cursor (for UI)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current_speed = walk_speed
	# Make the ray visible for debugging
	interaction_ray.debug_shape_custom_color = Color.RED
	interaction_ray.debug_shape_thickness = 2

func _input(event):
	# MOUSE LOOK: Only when right mouse button is held
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.4, 1.4)
	
	# ESC key to pause/quit (optional)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# LEFT CLICK to interact with clues
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_interactable:
			print("🖱️ Left click on: ", current_interactable.name)
			# Show click cursor briefly
			CursorManager.set_cursor(CursorManager.CursorState.CLICK)
			# Open inspection view
			current_interactable.interact()
			# Reset cursor after delay
			await get_tree().create_timer(0.1).timeout
			if current_interactable:
				CursorManager.set_cursor(CursorManager.CursorState.HOVER)
			else:
				CursorManager.reset_cursor()

func _physics_process(delta):
	# Sprint
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = walk_speed

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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

func check_interaction():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		
		if collider and collider.has_method("get_interaction_text"):
			# Looking at an interactable object
			CursorManager.set_cursor(CursorManager.CursorState.HOVER)
			
			if current_interactable != collider:
				# Unfocus previous
				if current_interactable and current_interactable.has_method("on_unfocus"):
					print("🔄 Unfocusing previous: ", current_interactable.name)
					current_interactable.on_unfocus()
				
				# Focus new
				current_interactable = collider
				if current_interactable.has_method("on_focus"):
					print("🔄 Focusing new: ", current_interactable.name)
					current_interactable.on_focus()
				
				# Show the UI prompt
				interaction_ui.show_prompt(collider.get_interaction_text())
			return
	
	# If we get here, we're NOT looking at any interactable
	
	# Unfocus any previously focused object
	if current_interactable:
		if current_interactable.has_method("on_unfocus"):
			print("🔄 Unfocusing (looked away): ", current_interactable.name)
			current_interactable.on_unfocus()
		current_interactable = null
	
	# Hide the UI prompt
	interaction_ui.hide_prompt()
	
	# Reset cursor to normal
	CursorManager.reset_cursor()
