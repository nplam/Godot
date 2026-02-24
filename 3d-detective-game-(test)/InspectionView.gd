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
	
	# Check for camera with name "InspectionCamera"
	var camera = viewport.find_child("InspectionCamera", true, false)
	if camera:
		camera.current = true
		print("   InspectionCamera found and set to current")
		print("   Camera position: ", camera.position)
	else:
		print("   ⚠️ InspectionCamera not found - check scene!")
	
	# Check for light with name "InspectionLight"
	var light = viewport.find_child("InspectionLight", true, false)
	if light:
		print("   InspectionLight found")
		print("   Light rotation: ", light.rotation)
	else:
		print("   ⚠️ InspectionLight not found - check scene!")
	
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
	# Clear previous objects (keep camera and light)
	for child in viewport.get_children():
		if child.name == "InspectionCamera" or child.name == "InspectionLight":
			continue
		child.queue_free()
	
	print("📦 Creating object copy for viewport")
	
	var object_copy = interactable.duplicate()
	viewport.add_child(object_copy)
	
	# CRITICAL: Position the object where the camera can see it
	object_copy.position = Vector3(0, 0, -2)  # 2 units in front of camera
	object_copy.rotation = Vector3(0, 0, 0)
	
	# Force scale to be normal
	object_copy.scale = Vector3(1, 1, 1)
	
	print("   Object position: ", object_copy.position)
	
	# Find and highlight the mesh
	var mesh = object_copy.find_child("*MeshInstance3D*", true, false)
	if mesh:
		print("   Mesh found: ", mesh.name)
		print("   Original material: ", mesh.material_override)
		
		# FORCE VISIBILITY: Apply bright glowing material
		var glow_material = StandardMaterial3D.new()
		glow_material.albedo_color = Color(1, 0, 0)  # Bright red
		glow_material.emission_enabled = true
		glow_material.emission = Color(1, 0, 0)  # Red emission
		glow_material.emission_energy_multiplier = 2.0
		mesh.material_override = glow_material
		print("   🔆 Applied bright red glowing material")
		
		# Make sure the mesh is visible
		mesh.visible = true
	else:
		print("   ❌ No mesh found in copied object!")
		
		# Create a visible fallback cube
		print("   Creating fallback red cube")
		var fallback = MeshInstance3D.new()
		fallback.mesh = BoxMesh.new()
		fallback.position = Vector3(0, 0, -2)
		
		var red_mat = StandardMaterial3D.new()
		red_mat.albedo_color = Color(1, 0, 0)
		fallback.material_override = red_mat
		viewport.add_child(fallback)
	
	# Double-check camera
	var camera = viewport.find_child("InspectionCamera", true, false)
	if camera:
		print("   Camera position: ", camera.position)
		print("   Camera is current: ", camera.current)
	
	print("✅ Object setup complete")

func _on_take():
	print("Take button pressed")
	
	if on_take_callback.is_valid():
		on_take_callback.call()
	
	# Disable viewport rendering
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	# Remove objects (keep InspectionCamera and InspectionLight)
	for child in viewport.get_children():
		if child.name == "InspectionCamera" or child.name == "InspectionLight":
			continue
		child.queue_free()
	
	CursorManager.reset_cursor()
	hide()
	
	# Re-enable after a frame
	await get_tree().process_frame
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE

func _on_cancel():
	print("Cancel button pressed")
	
	if on_cancel_callback.is_valid():
		on_cancel_callback.call()
	
	# Disable viewport rendering
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	# Remove objects (keep InspectionCamera and InspectionLight)
	for child in viewport.get_children():
		if child.name == "InspectionCamera" or child.name == "InspectionLight":
			continue
		child.queue_free()
	
	CursorManager.reset_cursor()
	hide()
	
	# Re-enable after a frame
	await get_tree().process_frame
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
