extends CharacterBody3D

const BASE_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 10.5
const FRICTION = 50.0  # Higher = more grip
const AIR_CONTROL = 0.3  # Reduces movement control in mid-air
const LEAN_AMOUNT = 0.2  # How much the character leans
const LEAN_SPEED = 10.0  # How fast the lean engages/resets

@export var move_speed = BASE_SPEED  # Default to walking speed
@export var turn_speed = 5.0
@export var acceleration = 20
@export var jump_strength = 5.0
@export var gravity = 9.8

@export var player_model: Node3D
@export var camera_pivot: Node3D  # Assign this to the Node3D that rotates with the camera
@export var anim_player: AnimationPlayer  # Assign the AnimationPlayer in the inspector

var is_jumping = false  # Tracks if the player is jumping
var has_played_jump = false  # Ensures jump animation plays first before falling
var lean_target = 0.0  # Stores desired lean angle

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

		# Ensure we play jump first before falling
		if !has_played_jump:
			has_played_jump = true
			anim_player.play("player/jump_start")
		elif has_played_jump and anim_player.current_animation != "player/jump_start":
			anim_player.play("player/falling")

	# Check if the sprint button (Shift) is pressed
	if Input.is_action_pressed("sprint"):
		move_speed = SPRINT_SPEED  # Increase speed when sprinting
	else:
		move_speed = BASE_SPEED  # Return to normal speed

	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_jumping = true
		has_played_jump = false  # Reset so jump animation plays
		velocity.y = JUMP_VELOCITY

		# Play jump animation immediately
		anim_player.play("player/jump_start")

	# Get input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Convert input direction relative to the camera
	var camera_basis = camera_pivot.global_transform.basis  # Get camera's rotation
	var move_dir = (camera_basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()  # Inverted X and Z

	# Zero out Y movement (prevent flying)
	move_dir.y = 0
	move_dir = move_dir.normalized()

	# Adjust acceleration based on whether we're in the air
	var current_acceleration = acceleration
	if not is_on_floor():
		current_acceleration *= AIR_CONTROL  # Reduce movement control in air

	# Handle movement
	if move_dir.length() > 0.01:
		velocity.x = move_toward(velocity.x, move_dir.x * move_speed, current_acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * move_speed, current_acceleration * delta)

		# Rotate player model towards movement direction
		var target_rotation = atan2(-move_dir.x, -move_dir.z)  
		var current_rotation = player_model.rotation.y
		player_model.rotation.y = lerp_angle(current_rotation, target_rotation, turn_speed * delta)

		# Handle animations **only if not jumping**
		if is_on_floor() and not is_jumping:
			if move_speed > BASE_SPEED:
				_play_animation("player/run")  # Play run animation if sprinting
			else:
				_play_animation("player/jog")  # Play jog animation if walking
	else:
		# Apply friction when no input is detected
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)

		# Play idle animation when not moving and not jumping
		if is_on_floor() and not is_jumping:
			_play_animation("player/idle")

	# Reset jumping state **only when landing**
	if is_on_floor() and is_jumping:
		is_jumping = false  # Reset jump flag
		has_played_jump = false  # Reset jump state so it can play again
		_play_animation("player/idle")  # Play idle when landing

	# **Leaning System: Only When Pressing "A" or "D"**
	var forward_dir = camera_pivot.global_transform.basis.z  # Camera's forward direction
	var move_direction = velocity.normalized()  # Player's movement direction
	var facing_forward = forward_dir.dot(move_direction) < 0  # Check if moving forward

	if Input.is_action_pressed("move_left"):
		lean_target = LEAN_AMOUNT if facing_forward else -LEAN_AMOUNT  # Lean left (flip if moving backward)
	elif Input.is_action_pressed("move_right"):
		lean_target = -LEAN_AMOUNT if facing_forward else LEAN_AMOUNT  # Lean right (flip if moving backward)
	else:
		lean_target = 0.0  # Reset lean when keys are released
	# Smoothly interpolate to target lean
	player_model.rotation.z = lerp(player_model.rotation.z, lean_target, LEAN_SPEED * delta)

	move_and_slide()

# Function to play animations without restarting the same one
func _play_animation(anim_name: String) -> void:
	# Don't override jump/falling animation if still in the air
	if is_jumping and anim_name not in ["player/jump_start", "player/falling"]:
		return

	# Play animation only if it's not already playing
	if anim_player and anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
