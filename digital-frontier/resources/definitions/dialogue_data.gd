class_name DialogueData
extends IdentifiableResource
## Branching dialogue tree stored as data.

## Nodes keyed by StringName node_id. Each node:
## { "speaker": String, "text": String, "choices": [{ "label": String, "next": StringName, "condition": StringName }] }
@export var nodes: Dictionary = {}
@export var entry_node_id: StringName = &"start"
