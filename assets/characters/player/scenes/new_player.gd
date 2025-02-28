extends CharacterBody3D

const BASE_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 10.5
const FRICTION = 80.0  # Higher = more grip
const AIR_CONTROL = 0.3  # Reduces movement control in mid-air
const LEAN_AMOUNT = 0.2  # How much the character leans
const LEAN_SPEED = 10.0  # How fast the lean engages/resets
const MAX_COMBAT_ROTATION = 0.4  # Maximum left/right rotation in combat stance
const ANIMATION_BLEND_TIME = 0.2  # Smooth animation transition time

@export var move_speed = BASE_SPEED  # Default to walking speed
@export var turn_speed = 5.0
@export var acceleration = 20
@export var jump_strength = 5.0
@export var gravity = 9.8

@export var player_model: Node3D
@export var camera_pivot: Node3D  # Assign this to the Node3D that rotates with the camera
@export var anim_player: AnimationPlayer  # Assign the AnimationPlayer in the inspector
@export var reticle: Node3D  # Assign the 3D reticle target the player should always face

var is_jumping = false  # Tracks if the player is jumping
var has_played_jump = false  # Ensures jump animation plays first before falling
var lean_target = 0.0  # Stores desired lean angle

var combat_stance = false  # Tracks whether combat stance is active
var combat_rotation = 0.0  # Stores slight side rotation in combat stance

func _input(event):
	if event.is_action_pressed("combat_stance"):
		combat_stance = !combat_stance  # Toggle combat mode

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

		# Ensure we play jump first before falling
		if !has_played_jump:
			has_played_jump = true
			_play_animation("player/jump_start")
		elif has_played_jump and anim_player.current_animation != "player/jump_start":
			_play_animation("player/falling")

	# Check if the sprint button (Shift) is pressed
	if Input.is_action_pressed("sprint") and not combat_stance:
		move_speed = SPRINT_SPEED  # Increase speed when sprinting
	else:
		move_speed = BASE_SPEED  # Return to normal speed

	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_jumping = true
		has_played_jump = false  # Reset so jump animation plays
		velocity.y = JUMP_VELOCITY
		# Play jump animation immediately
		_play_animation("player/jump_start")

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

	if combat_stance:
		# 🛑 Combat Mode: Always Face Camera Reticle
		if reticle:
			var target_direction = (reticle.global_transform.origin - player_model.global_transform.origin).normalized()
			player_model.look_at(player_model.global_transform.origin - target_direction, Vector3.UP)

		# Movement in combat stance
		if move_dir.length() > 0.01:
			velocity.x = move_toward(velocity.x, move_dir.x * move_speed, current_acceleration * delta)
			velocity.z = move_toward(velocity.z, move_dir.z * move_speed, current_acceleration * delta)

			# 🔄 Reverse jogging animation when moving backward in combat stance
			if input_dir.y > 0:  # Pressing "S" (move_back)
				_play_animation("player/jog", -1.0)  # Reverse animation
			else:
				_play_animation("player/jog", 1.0)  # Normal animation speed

			# 🌀 **Slight rotation when moving left/right in combat**
			var side_movement = input_dir.x  # Left (-1) or Right (+1)
			combat_rotation = lerp(combat_rotation, side_movement * MAX_COMBAT_ROTATION, delta * turn_speed)

		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
			_play_animation("player/idle")  # Stand still in combat stance

		# Apply **limited combat rotation** while still facing the reticle
		player_model.rotation.y += combat_rotation * delta * turn_speed

	else:
		# 🌀 Free rotation outside combat stance
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
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
			#_play_animation("player/idle")  # Play idle when stopping
	if (velocity.x == 0 && velocity.z == 0) && is_on_floor():
		_play_animation("player/idle")

	# Reset jumping state **only when landing**
	if is_on_floor() and is_jumping:
		is_jumping = false  # Reset jump flag
		has_played_jump = false  # Reset jump state so it can play again
		_play_animation("player/idle")  # Play idle when landing
		
	move_and_slide()

# Function to smoothly transition between animations
func _play_animation(anim_name: String, speed: float = 1.0) -> void:
	# Ensure jump animations **always** play, even when standing still
	#print(anim_name)
	if anim_name in ["player/jump_start", "player/falling"]:
		anim_player.play(anim_name, -1, speed)
		anim_player.advance(ANIMATION_BLEND_TIME)  # Smoothly transition
		return  # Skip further checks so it **always plays**

	# Only play animation if it's different from the current one
	if anim_player and anim_player.current_animation != anim_name:
		anim_player.play(anim_name, -1, speed)
		anim_player.advance(ANIMATION_BLEND_TIME)  # Smoothly transition
