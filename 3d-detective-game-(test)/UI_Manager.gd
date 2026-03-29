# UI_Manager.gd - Complete version with Help and Intro buttons
extends CanvasLayer

@onready var intro_button = $IntroButton
@onready var intro_menu = $Intro

func _ready():
	print("\n🔍 UI MANAGER INITIALIZING...")
	
	# ============ HELP BUTTON ============
	var help_button = $HelpButton
	var help_menu = $HelpMenu
	
	print("   HelpButton: ", help_button)
	print("   HelpMenu: ", help_menu)
	
	if help_button and help_menu:
		help_button.pressed.connect(help_menu.show_menu)
		print("✅ Help button connected to help menu!")
	else:
		print("❌ Could not find help button or menu!")
		if not help_button:
			print("   - HelpButton not found! Check the node name.")
		if not help_menu:
			print("   - HelpMenu not found! Check the node name.")
	
	# ============ INTRO BUTTON ============
	print("\n   IntroButton: ", intro_button)
	print("   IntroMenu: ", intro_menu)
	
	if intro_button and intro_menu:
		intro_button.pressed.connect(_on_intro_button_pressed)
		print("✅ Intro button connected to intro menu!")
	else:
		print("❌ Could not find intro button or menu!")
		if not intro_button:
			print("   - IntroButton not found! Check the node name.")
		if not intro_menu:
			print("   - IntroMenu not found! Check the node name.")
	
	print("🔍 UI Manager ready\n")

func _on_intro_button_pressed():
	"""Called when intro button is clicked"""
	print("📖 Intro button clicked")
	SoundManager.play_click()
	
	if intro_menu and intro_menu.has_method("show_intro"):
		intro_menu.show_intro()
		print("   Intro menu shown")
	else:
		print("   ⚠️ Cannot show intro - menu not found or missing show_intro method")
