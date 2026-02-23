extends Node

# Define the different cursor states we'll use
enum CursorState {
	NORMAL,    # Default arrow
	HOVER,     # Pointing hand (when over a clue)
	CLICK      # Click feedback (when pressing E)
}

# Track current state
var current_state = CursorState.NORMAL

# This function changes the cursor based on the state
func set_cursor(state: CursorState):
	current_state = state
	
	# Match the state to a built-in cursor shape
	match state:
		CursorState.NORMAL:
			# Standard arrow cursor
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			print("🖱️ Cursor: NORMAL (arrow)")  # Debug
		
		CursorState.HOVER:
			# Pointing hand - perfect for interactable objects
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			print("🖱️ Cursor: HOVER (pointing hand)")  # Debug
		
		CursorState.CLICK:
			# Brief feedback when pressing E (use drag or busy cursor)
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			print("🖱️ Cursor: CLICK (drag)")  # Debug

# Convenience function to reset to normal
func reset_cursor():
	set_cursor(CursorState.NORMAL)
