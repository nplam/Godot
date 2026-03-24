# UI_Manager.gd - Attach this to CanvasLayer
extends CanvasLayer

func _ready():
	# Find the help button and help menu
	var help_button = $HelpButton
	var help_menu = $HelpMenu
	
	# Debug: print what we found
	print("🔍 UI Manager - Finding UI elements:")
	print("   HelpButton: ", help_button)
	print("   HelpMenu: ", help_menu)
	
	# Connect the button to the menu
	if help_button and help_menu:
		help_button.pressed.connect(help_menu.show_menu)
		print("✅ Help button connected to help menu!")
	else:
		print("❌ Could not find help button or menu!")
		if not help_button:
			print("   - HelpButton not found! Check the node name.")
		if not help_menu:
			print("   - HelpMenu not found! Check the node name.")
