extends Control

# Declare node references - match your scene exactly
@onready var main_panel: Control = $MainPanel
@onready var object_name_label: Label = $MainPanel/ObjectName
@onready var description_label: RichTextLabel = $MainPanel/Description
@onready var viewport_container = $MainPanel/ViewportContainer          # Name: ViewportContainer
@onready var viewport: SubViewport = $MainPanel/ViewportContainer/SubViewport   # SubViewport inside
@onready var close_button: Button = $MainPanel/CloseButton              # Fixed typo
@onready var take_button: Button = $MainPanel/ButtonContainer/TakeEvidenceButton
@onready var cancel_button: Button = $MainPanel/ButtonContainer/CancelButton

# Variables to store the current interactable and callbacks
var current_interactable = null
var on_take_callback: Callable
var on_cancel_callback: Callable

func _ready():
	print("🔧 INSPECTION VIEW READY")
	print("   main_panel: ", main_panel)
	print("   viewport_container: ", viewport_container)
	print("   viewport: ", viewport)
	print("   close_button: ", close_button)
	print("   take_button: ", take_button)
	print("   cancel_button: ", cancel_button)
	
	# Connect signals
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)
	else:
		print("⚠️ cancel_button is null!")
	
	if take_button:
		take_button.pressed.connect(_on_take)
	else:
		print("⚠️ take_button is null!")
	
	if close_button:
		close_button.pressed.connect(_on_cancel)
	else:
		print("⚠️ close_button is null!")
	
	# Check camera
	var camera = viewport.find_child("InspectionCamera", true, false)
	if camera:
		camera.current = true
		print("   InspectionCamera found and set to current")
		print("   Camera position: ", camera.position)
	else:
		print("   ⚠️ InspectionCamera not found - check scene!")
	
	# Check light
	var light = viewport.find_child("InspectionLight", true, false)
	if light:
		print("   InspectionLight found")
		print("   Light rotation: ", light.rotation)
	else:
		print("   ⚠️ InspectionLight not found - check scene!")
	
	hide()

func inspect(interactable, take_callback: Callable, cancel_callback: Callable):
	print("Inspect called for: ", interactable.object_name)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	CursorManager.set_cursor(CursorManager.CursorState.NORMAL)
	
	current_interactable = interactable
	on_take_callback = take_callback
	on_cancel_callback = cancel_callback
	
	object_name_label.text = interactable.object_name
	description_label.text = "[b]" + interactable.object_name + "[/b]\n\n" + interactable.examination_text
	
	show_object_in_viewport(interactable)
	show()

func show_object_in_viewport(interactable):
	# Clear previous objects (keep camera and light)
	for child in viewport.get_children():
		if child.name == "InspectionCamera" or child.name == "InspectionLight":
			continue
		child.queue_free()
	
	print("📦 Creating object copy for viewport")
	print("Viewport size: ", viewport.size)
	
	# Test cube (bright green)
	var test_cube = MeshInstance3D.new()
	test_cube.mesh = BoxMesh.new()
	test_cube.position = Vector3(1, 0, -2)
	test_cube.scale = Vector3(0.3, 0.3, 0.3)
	var green_mat = StandardMaterial3D.new()
	green_mat.albedo_color = Color(0, 1, 0)
	green_mat.emission_enabled = true
	green_mat.emission = Color(0, 1, 0)
	test_cube.material_override = green_mat
	viewport.add_child(test_cube)
	print("   ✅ Added bright green test cube at (1,0,-2)")
	
	# Clue object
	var object_copy = interactable.duplicate()
	viewport.add_child(object_copy)
	object_copy.position = Vector3(0, 0, -2)
	object_copy.rotation = Vector3(0, 0, 0)
	object_copy.scale = Vector3(1, 1, 1)
	print("   Object position: ", object_copy.position)
	
	# Highlight clue
	var mesh = object_copy.find_child("*MeshInstance3D*", true, false)
	if mesh:
		var red_mat = StandardMaterial3D.new()
		red_mat.albedo_color = Color(1, 0, 0)
		red_mat.emission_enabled = true
		red_mat.emission = Color(1, 0, 0)
		mesh.material_override = red_mat
		mesh.visible = true
		print("   🔆 Applied bright red glowing material")
	else:
		print("   ❌ No mesh found in copied object!")
	
	# After adding all objects to the viewport
	await get_tree().process_frame
	# Optionally, force the viewport to update
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Force the viewport to generate its render texture.
	await RenderingServer.frame_post_draw
	
	# Confirm camera
	var camera = viewport.find_child("InspectionCamera", true, false)
	if camera:
		print("   Camera position: ", camera.position)
		print("   Camera is current: ", camera.current)
	
	print("✅ Object setup complete")

func _on_take():
	print("Take button pressed")
	if on_take_callback.is_valid():
		on_take_callback.call()
	
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	for child in viewport.get_children():
		if child.name == "InspectionCamera" or child.name == "InspectionLight":
			continue
		child.queue_free()
	
	CursorManager.reset_cursor()
	hide()
	await get_tree().process_frame
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE

func _on_cancel():
	print("Cancel button pressed")
	if on_cancel_callback.is_valid():
		on_cancel_callback.call()
	
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	for child in viewport.get_children():
		if child.name == "InspectionCamera" or child.name == "InspectionLight":
			continue
		child.queue_free()
	
	CursorManager.reset_cursor()
	hide()
	await get_tree().process_frame
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
