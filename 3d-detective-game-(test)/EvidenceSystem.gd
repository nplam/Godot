extends Node

# Dictionary to store all collected evidence
# Key: evidence_id (String)
# Value: Dictionary with keys: id, name, description, texture, time
var collected_evidence = {}

# Signal emitted whenever new evidence is collected
signal evidence_collected(evidence_id, data)

# Add evidence to the collection
func collect_evidence(id: String, name: String, description: String, texture = null) -> bool:
	if not collected_evidence.has(id):
		collected_evidence[id] = {
			"id": id,
			"name": name,
			"description": description,
			"texture": texture,
			"time": Time.get_datetime_string_from_system()
		}
		print("Evidence collected: ", name, "(ID: ", id, ")")
		evidence_collected.emit(id, collected_evidence[id])
		return true
	return false
	
# Check if a specific evidence ID has been collected
func has_evidence(id: String) -> bool:
	return collected_evidence.has(id)

# Get data for a specific evidence ID
func get_evidence(id: String):
	return collected_evidence.get(id)

# Get an array of all collected evidence data
func get_all_evidence() -> Array:
	return collected_evidence.values()
	
