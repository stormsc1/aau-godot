extends CSGBox3D

@export var interact_prompt_text : String = "Press"

func get_interact_prompt_text() -> String:
	return interact_prompt_text

func interact() -> void:
	print("test")
