# HelpMenu.gd - Simple version
extends Control

func _ready():
	visible = false
	
	# Connect close button
	var close_btn = $Panel/CloseButton
	if close_btn:
		close_btn.pressed.connect(_on_close)

func _on_close():
	hide()

func show_menu():
	print("Help menu opened")
	visible = true
