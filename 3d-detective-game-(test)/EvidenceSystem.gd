# EvidenceSystem.gd
extends Node

var collected_evidence = {}  # id -> Dictionary (using Dictionary for simplicity)

signal evidence_collected(data)
signal evidence_removed(id)

func _ready():
	print("🔧 EVIDENCE SYSTEM READY")

func collect_evidence(data: Dictionary):
	if not collected_evidence.has(data.id):
		collected_evidence[data.id] = data
		evidence_collected.emit(data)
		print("📦 Evidence collected: ", data.name, " (ID: ", data.id, ")")
		return true
	return false

func remove_evidence(id: String):
	if collected_evidence.has(id):
		var data = collected_evidence[id]
		collected_evidence.erase(id)
		evidence_removed.emit(id)
		print("🗑️ Evidence removed: ", data.name, " (ID: ", id, ")")
		return data
	return null

func get_evidence(id: String):
	return collected_evidence.get(id)

func get_all_evidence() -> Array:
	return collected_evidence.values()

func has_evidence(id: String) -> bool:
	return collected_evidence.has(id)

func get_evidence_count() -> int:
	return collected_evidence.size()

func print_all_evidence():
	print("📋 EvidenceSystem contents (", collected_evidence.size(), " items):")
	for id in collected_evidence:
		var data = collected_evidence[id]
		print("   - ", id, ": ", data.name)
