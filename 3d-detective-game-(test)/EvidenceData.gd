# EvidenceData.gd
class_name EvidenceData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D

# Reference to the world object (not saved, just runtime reference)
var world_object: Node = null
