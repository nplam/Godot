# UVLight.gd - Handles UV light toggling and blood stain detection
extends Node3D

# References to our child nodes
@onready var visual_light: SpotLight3D = $SpotLight3D
@onready var detection_area: Area3D = $DetectionArea

# Track whether the light is on
var is_on: bool = false
var detected_stains: Array = []  # Keep track of stains currently in the light

func _ready():
	# Start with light off
	visual_light.visible = false
	detection_area.monitoring = false
	
	# Connect detection signals (BOTH entered and exited)
	detection_area.area_entered.connect(_on_area_entered)
	detection_area.area_exited.connect(_on_area_exited)   # ← This was missing!
	
	print("🔦 UV Light system ready on Hand node")

func _input(event):
	if event.is_action_pressed("toggle_uv"):
		toggle_light()

func toggle_light():
	is_on = !is_on
	visual_light.visible = is_on
	detection_area.monitoring = is_on
	
	if is_on:
		print("🔦 Light turned ON")
		print("   Energy: ", visual_light.light_energy)
		print("   Range: ", visual_light.spot_range)
		print("   Angle: ", visual_light.spot_angle)
		print("   Color: ", visual_light.light_color)
		print("   Cull Mask: ", visual_light.light_cull_mask)
		print("   Position: ", visual_light.position)
	else:
		print("UV Light OFF")
		reset_all_stains()  # Hide all stains when light turns off

func _on_area_entered(area: Area3D):
	if area.is_in_group("blood_stain") and area.has_method("on_uv_detected"):
		if not area in detected_stains:
			detected_stains.append(area)
			area.on_uv_detected()
			print("🩸 Blood stain entered. Total: ", detected_stains.size())

func _on_area_exited(area: Area3D):
	if area in detected_stains:
		detected_stains.erase(area)
		if area.has_method("reset_glow"):
			area.reset_glow()
		print("🩸 Blood stain exited. Remaining: ", detected_stains.size())

# Helper to hide all stains (used when light turns off)
func reset_all_stains():
	for stain in detected_stains:
		if is_instance_valid(stain) and stain.has_method("reset_glow"):
			stain.reset_glow()
	detected_stains.clear()
