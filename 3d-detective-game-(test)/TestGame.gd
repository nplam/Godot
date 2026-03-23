# TestGame.gd
extends Node

@onready var case_board = $CaseBoard
@onready var add_evidence_button = $AddTestEvidenceButton

func _ready():
	print("🧪 TEST GAME READY")
	print("Press C to open CaseBoard")
	print("Or click the button to add test evidence")
	
	# Connect button
	if add_evidence_button:
		add_evidence_button.pressed.connect(_add_test_evidence)
	
	# Optional: Auto-add test evidence after 1 second
	await get_tree().create_timer(1.0).timeout
	_add_test_evidence()

func _add_test_evidence():
	"""Add test evidence to case board"""
	print("\n📦 Adding test evidence...")
	
	# Create test evidence
	var test_evidence = [
		{
			"id": "shoe_1",
			"name": "Muddy Shoeprint",
			"type": 0,  # SHOEPRINT
			"texture": null,  # Add texture path if you have one
			"match_value": "loafers",  # Matches Mr. Bobby and Hector
			"description": "A muddy shoeprint with loafers pattern found at the crime scene"
		},
		{
			"id": "fp_1",
			"name": "Fingerprint",
			"type": 1,  # FINGERPRINT
			"texture": null,
			"match_value": "fp_001",  # Matches Mr. Bobby only
			"description": "Partial fingerprint lifted from the door handle"
		},
		{
			"id": "hair_1",
			"name": "Hair Strand",
			"type": 2,  # HAIR
			"texture": null,
			"match_value": "Brown",  # Matches Mr. Bobby and Hector
			"description": "A strand of brown hair found on the victim's clothing"
		}
	]
	
	# Add each evidence to case board
	for evidence in test_evidence:
		case_board.add_evidence(evidence)
	
	print("✅ Added ", test_evidence.size(), " test evidence items")
	
	# Show case board after adding evidence (optional)
	# case_board.show()
