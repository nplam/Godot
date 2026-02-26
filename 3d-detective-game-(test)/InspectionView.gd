extends Control

# Node references
@onready var main_panel: Control = $MainPanel
@onready var object_name_label: Label = $MainPanel/ObjectName
@onready var description_label: RichTextLabel = $MainPanel/Description
@onready var viewport_display: TextureRect = $MainPanel/ViewportDisplay
@onready var render_viewport: SubViewport = $MainPanel/RenderViewport
@onready var close_button: Button = $MainPanel/CloseButton
@onready var take_button: Button = $MainPanel/ButtonContainer/TakeEvidenceButton
@onready var cancel_button: Button = $MainPanel/ButtonContainer/CancelButton

# Variables
var current_interactable = null
var on_take_callback: Callable
var on_cancel_callback: Callable

func _ready():
	print("🔧 INSPECTION VIEW READY")
	
	# Connect buttons
	cancel_button.pressed.connect(_on_cancel)
	take_button.pressed.connect(_on_take)
	close_button.pressed.connect(_on_cancel)
	
	# Setup viewport
	render_viewport.world_3d = World3D.new()
	render_viewport.disable_3d = false
	render_viewport.transparent_bg = false
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	
	hide()

func inspect(interactable, take_callback: Callable, cancel_callback: Callable):
	print("Inspect called for: ", interactable.object_name)
	
	current_interactable = interactable
	on_take_callback = take_callback
	on_cancel_callback = cancel_callback
	
	object_name_label.text = interactable.object_name
	description_label.text = "[b]" + interactable.object_name + "[/b]\n\n" + interactable.examination_text
	
	await setup_viewport(interactable)
	show()

func setup_viewport(interactable):
	# Clear everything in viewport
	for child in render_viewport.get_children():
		child.queue_free()
	
	# Add camera
	var cam = Camera3D.new()
	cam.name = "InspectionCamera"
	cam.current = true
	cam.position = Vector3(0, 0, 3)
	render_viewport.add_child(cam)
	
	# Add light
	var light = DirectionalLight3D.new()
	light.name = "InspectionLight"
	light.rotation = Vector3(-45, 45, 0)
	light.light_energy = 1.5
	render_viewport.add_child(light)
	
	# Add a subtle ambient light to fill shadows
	var ambient = DirectionalLight3D.new()
	ambient.name = "AmbientLight"
	ambient.rotation = Vector3(45, -45, 0)
	ambient.light_energy = 0.5
	render_viewport.add_child(ambient)
	
	# Add the actual clue object
	var object_copy = interactable.duplicate()
	render_viewport.add_child(object_copy)
	
	# Position it nicely
	object_copy.position = Vector3(0, 0, -2)
	object_copy.rotation = Vector3(0, 0, 0)
	object_copy.scale = Vector3(1, 1, 1)
	
	# Make the camera look at the clue
	cam.look_at(object_copy.position, Vector3.UP)
	
	# Optional: Add a subtle rotation animation
	# This makes the clue slowly rotate for better viewing
	var tween = create_tween()
	tween.tween_property(object_copy, "rotation:y", object_copy.rotation.y + 6.28, 10.0)
	tween.set_loops()
	
	# Wait for first render
	await RenderingServer.frame_post_draw
	
	# Assign texture to display (remove any debug tint)
	viewport_display.texture = render_viewport.get_texture()
	viewport_display.modulate = Color.WHITE
	
	print("✅ Clue object displayed: ", interactable.object_name)

func _on_take():
	print("Take button pressed")
	if on_take_callback.is_valid():
		on_take_callback.call()
	
	# Cleanup
	for child in render_viewport.get_children():
		child.queue_free()
	viewport_display.texture = null
	hide()

func _on_cancel():
	print("Cancel button pressed")
	if on_cancel_callback.is_valid():
		on_cancel_callback.call()
	
	# Cleanup
	for child in render_viewport.get_children():
		child.queue_free()
	viewport_display.texture = null
	hide()
