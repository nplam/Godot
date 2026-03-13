# FingerprintBrush_Simple.gd - Ultra simple version
extends Node3D  # NOT RigidBody3D for now

var is_active: bool = false

func _ready():
	hide()
	print("🖌️ Simple brush ready - HIDDEN")

func toggle_active():
	is_active = !is_active
	visible = is_active
	print("🖌️ Brush toggled: ", "visible" if is_active else "hidden")
