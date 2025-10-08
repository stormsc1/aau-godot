extends Area3D 
class_name JumpPad 

@export var impulse_vector : Vector3 = Vector3(0, 10, 0)

func _ready():  
	body_entered.connect(impulse)
	
func impulse(body):
	if body.has_method("add_impulse"):
		body.add_impulse(impulse_vector)
