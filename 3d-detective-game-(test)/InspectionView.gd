extends Control

# Declare node references - these paths must match YOUR scene exactly
@onready var main_panel: Panel = $MainPanel
@onready var object_name_label: Label = $MainPanel/ObjectName
@onready var description_label: RichTextLabel = $MainPanel/Description
@onready var viewport_container: Control = $MainPanel/ViewportContainer
@onready var viewport: SubViewport = $MainPanel/ViewportContainer/SubViewport
@onready var close_button: Button = $MainPanel/CloseButton
@onready var take_button: Button = $MainPanel/ButtonContainer/TakeEvidenceButton
@onready var cancel_button: Button = $MainPanel/ButtonContainer/CancelButton

# Variables to store the current interactable and callbacks
var current_interactable = null
var on_take_callback: Callable
var on_cancel_callback: Callable

func _ready():
	print("🔧 INSPECTION VIEW READY")
	print("   object_name_label: ", object_name_label)
	print("   description_label: ", description_label)
	print("   viewport: ", viewport)
	
	# Check camera
	var camera = viewport.find_child("*Camera3D*", true, false)
	if camera:
		print("   Camera found: ", camera)
		print("   Camera position: ", camera.position)
		print("   Camera current: ", camera.current)
	else:
		print("   ⚠️ No camera found in viewport!")
		# Add a camera if missing
		var new_camera = Camera3D.new()
		new_camera.current = true
		new_camera.position = Vector3(0, 0, 3)
		viewport.add_child(new_camera)
		print("   Added new camera at position: ", new_camera.position)
	
	# Check lighting
	var light = viewport.find_child("*Light3D*", true, false)
	if light:
		print("   Light found: ", light)
	else:
		print("   ⚠️ No light found in viewport!")
		var new_light = DirectionalLight3D.new()
		new_light.rotation = Vector3(-45, 45, 0)
		viewport.add_child(new_light)
		print("   Added new light")
	
	hide()
	cancel_button.pressed.connect(_on_cancel)
	take_button.pressed.connect(_on_take)
	close_button.pressed.connect(_on_cancel)

func inspect(interactable, take_callback: Callable, cancel_callback: Callable):
	print("Inspect called for: ", interactable.object_name)  # Debug
	# Make sure cursor is visible for UI interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	CursorManager.set_cursor(CursorManager.CursorState.NORMAL)
	
	current_interactable = interactable
	on_take_callback = take_callback
	on_cancel_callback = cancel_callback
	
	# Set up the UI
	object_name_label.text = interactable.object_name
	description_label.text = "[b]" + interactable.object_name + "[/b]\n\n" + interactable.examination_text
	
	# Show the 3D object in the viewport
	show_object_in_viewport(interactable)
	
	# Show the inspection view
	show()
	
	# Optional: Pause the game
	# get_tree().paused = true

func show_object_in_viewport(interactable):
	# Clear previous content
	for child in viewport.get_children():
		child.queue_free()
	
	print("📦 Creating object copy for viewport")
	
	# Create a copy of the interactable object for inspection
	var object_copy = interactable.duplicate()
	viewport.add_child(object_copy)
	
	# Print debug info
	print("   Object copy created: ", object_copy)
	print("   Original position: ", interactable.position)
	
	# Position the object nicely for viewing
	object_copy.position = Vector3(0, 0, -2)  # 2 meters in front of camera
	object_copy.rotation = Vector3(0, 0, 0)
	
	print("   New position: ", object_copy.position)
	
	# Make sure it has a mesh
	var mesh = object_copy.find_child("*MeshInstance3D*", true, false)
	if mesh:
		print("   Mesh found: ", mesh)
		print("   Mesh visible: ", mesh.visible)
	else:
		print("   ⚠️ No mesh found in copied object!")
	
	# Add a light if there isn't one
	if viewport.get_child_count() == 1:  # Only the object, no light
		print("   Adding temporary light")
		var light = DirectionalLight3D.new()
		light.rotation = Vector3(-45, 45, 0)  # Angle the light
		viewport.add_child(light)
	
	print("✅ Object added to viewport")

func _on_take():
	print("Take button pressed")  # Debug
	# Call the take callback (which will collect evidence)
	# Return to game mode (optional)
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	CursorManager.reset_cursor()
	if on_take_callback.is_valid():
		on_take_callback.call(current_interactable)
	# Hide and unpause
	hide()
	# get_tree().paused = false

func _on_cancel():
	print("Cancel button pressed")  # Debug
	# Just close the inspection view
	if on_cancel_callback.is_valid():
		on_cancel_callback.call()
	
	# Hide and unpause
	hide()
	# get_tree().paused = false
