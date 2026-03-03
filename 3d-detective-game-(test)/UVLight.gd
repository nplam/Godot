# UVLight.gd - Handles UV light toggling and blood stain detection
extends Node3D

# References to our child nodes
@onready var visual_light: SpotLight3D = $SpotLight3D
@onready var detection_area: Area3D = $DetectionArea

# Track whether the light is on
var is_on: bool = false

func _ready():
	# Start with light off
	visual_light.visible = false
	detection_area.monitoring = false
	
	# Connect the detection signal
	detection_area.area_entered.connect(_on_area_entered)
	
	print("🔦 UV Light system ready on Hand node")

func _input(event):
	# Toggle with F key (make sure you have 'toggle_uv' in Input Map)
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

func _on_area_entered(area: Area3D):
	# Check if whatever entered our detection area is a blood stain
	if area.is_in_group("blood_stain") and area.has_method("on_uv_detected"):
		print("🩸 Blood stain detected under UV light!")
		area.on_uv_detected()
