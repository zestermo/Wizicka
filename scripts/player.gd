extends CharacterBody3D

@export var speed = 5.0
@export var jump_strength = 5.0
@export var gravity = 9.8

@onready var camera_pivot: Node3D = $CameraPivot
@export var anim_player: AnimationPlayer

var current_animation = "" # Track the last played animation

func _ready():
	if anim_player:
		print("[DEBUG] AnimationPlayer found! Animations ready to go!")
		anim_player.play("iddle") # Ensure idle plays at start
		current_animation = "iddle"

func _physics_process(delta):
	# 1️⃣ Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	var animation_to_play = "iddle"  # Default animation

	# 2️⃣ Read Input for Movement
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x += 1
	if Input.is_action_pressed("move_right"):
		input_dir.x -= 1

	input_dir = input_dir.normalized()

	# 3️⃣ Convert 2D Input into 3D Direction Based on Camera Orientation
	var direction = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var move_basis = camera_pivot.global_transform.basis
		move_basis = Basis(
			Vector3(move_basis.x.x, 0, move_basis.x.z),
			Vector3(0,              1, 0),
			Vector3(move_basis.z.x, 0, move_basis.z.z)
		).orthonormalized()
		
		var forward = -move_basis.z
		var right = move_basis.x

		direction = (forward * input_dir.y + right * input_dir.x).normalized()
		animation_to_play = "walk"  # Walking animation

	# 4️⃣ Jumping Animation
	if Input.is_action_just_pressed("jump") and is_on_floor():
		animation_to_play = "jump"

	# 5️⃣ Only Change Animation If It’s Different
	if anim_player and animation_to_play != current_animation:
		print("[DEBUG] Switching animation to:", animation_to_play)
		anim_player.play(animation_to_play)
		current_animation = animation_to_play

	# 6️⃣ Update Movement
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_strength

	move_and_slide()	
