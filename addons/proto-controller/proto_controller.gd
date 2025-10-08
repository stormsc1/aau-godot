# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = true
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = true
## Can we interact?
@export var can_interact : bool = true

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 10.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 7.5
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "move_left"
## Name of Input Action to move Right.
@export var input_right : String = "move_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "move_forward"
## Name of Input Action to move Backward.
@export var input_back : String = "move_backwards"
## Name of Input Action to Jump.
@export var input_jump : String = "jump"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to Interact.
@export var input_interact : String = "interact"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var interact_target = null

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var interact_ray : RayCast3D = $Head/Camera3D/InteractRay
@onready var interact_prompt : Label = $CanvasLayer/InteractPrompt

func add_impulse(impulse: Vector3) -> void:
	velocity += impulse

func add_radial_impulse(origin: Vector3, strength: float, radius: float, upwards_modifier: float = 0.0) -> void:
	var dir := global_transform.origin - origin
	var dist := dir.length()
	if dist <= 0.001 or dist > radius:
		return
	dir = dir.normalized()
	dir.y += upwards_modifier
	dir = dir.normalized()
	# Simple linear falloff (you can swap to quadratic if you prefer)
	var falloff := 1.0 - (dist / radius)
	velocity += dir * (strength * falloff)

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Interaction
	if can_interact and Input.is_action_just_pressed(input_interact):
		try_interact()
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _process(delta) -> void:
	if can_interact:
		process_interact()

@export var accel_ground: float = 30.0
@export var accel_air: float = 8.0
@export var friction: float = 20.0

func _physics_process(delta: float) -> void:
	# Freefly (noclip)
	if can_freefly and freeflying:
		var input_free: Vector2 = Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion: Vector3 = (head.global_basis * Vector3(input_free.x, 0, input_free.y)).normalized() * freefly_speed * delta
		move_and_collide(motion)
		return

	# Gravity
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	# Jump (one-shot)
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	# Sprint
	move_speed = sprint_speed if (can_sprint and Input.is_action_pressed(input_sprint)) else base_speed

	# Desired move (world space)
	var input_dir: Vector2 = Input.get_vector(input_left, input_right, input_forward, input_back) if can_move else Vector2.ZERO
	var wish_dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Current & target horizontal velocities
	var v2: Vector2 = Vector2(velocity.x, velocity.z)
	var target_v2: Vector2 = Vector2(wish_dir.x, wish_dir.z) * move_speed

	# Accel toward target (add deltas; don't set)
	var accel: float = accel_ground if is_on_floor() else accel_air
	var dv: Vector2 = target_v2 - v2
	var max_step: float = accel * delta
	if dv.length() > max_step:
		dv = dv.normalized() * max_step
	v2 += dv

	# Ground friction when no input
	if is_on_floor() and input_dir == Vector2.ZERO and not is_zero_approx(v2.length()):
		var drop: float = min(friction * delta, v2.length())
		v2 = v2.move_toward(Vector2.ZERO, drop)

	# Write back horizontal velocity
	velocity.x = v2.x
	velocity.z = v2.y

	move_and_slide()

## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func process_interact():
	interact_ray.force_raycast_update()
	var hit = interact_ray.get_collider()
	if hit and hit.is_in_group("interactable"):
		interact_target = hit
		interact_prompt.visible = true
		if interact_target.has_method("get_interact_prompt_text"):
			interact_prompt.text = "E to %s" % interact_target.get_interact_prompt_text()
		else:
			interact_prompt.text = "E to Interact"
	else:
		interact_target = null
		interact_prompt.visible = false

# Called when press interact
func try_interact():
	# Call thje "interact" interface method if the object has one.
	if interact_target and interact_target.has_method("interact"):
		interact_target.interact()
		
## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
	if can_interact and not InputMap.has_action(input_interact):
		push_error("Interaction disabled. No InputAction found for input_interact: " + input_interact)
		can_interact = false
