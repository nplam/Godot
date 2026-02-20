# Player.gd
extends CharacterBody3D

# Movement variables
const SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.002

# Node references
@export var head: Node3D
@export var camera: Camera3D

var current_speed: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_speed = SPEED

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -1.4, 1.4)  # Limit vertical look

func _physics_process(delta):
	# Handle sprint
	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED
	else:
		current_speed = SPEED
	
	# Get input direction
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
