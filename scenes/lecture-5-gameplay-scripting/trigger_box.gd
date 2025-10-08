extends Area3D

signal character_entered

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		# $"../World/Door".open()
		character_entered.emit()
	
