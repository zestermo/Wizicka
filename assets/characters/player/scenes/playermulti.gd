extends CharacterBody3D

const BASE_SPEED = 3.5
const SPRINT_SPEED = 5.5
const JUMP_VELOCITY = 8.5
const FRICTION = 150.0
const AIR_CONTROL = 0.3
const LEAN_AMOUNT = 0.2
const LEAN_SPEED = 10.0
const MAX_COMBAT_ROTATION = 0.4
const ANIMATION_BLEND_TIME = 0.2
const LERP_VELOCITY: float = 0.15  # For smooth rotation

# Health, Mana, and Stamina
@export var max_health: int = 100
@export var max_mana: int = 100
@export var max_stamina: int = 100

var health: int = max_health
var mana: int = max_mana
var stamina: int = max_stamina

@export var mana_regen_rate: float = 5.0  # Mana regenerates per second
@export var stamina_regen_rate: float = 10.0  # Stamina regenerates per second
@export var stamina_drain_sprint: float = 20.0  # Stamina drain per second while sprinting
@export var stamina_regen_delay: float = 1.5  # Delay before stamina starts regenerating

var stamina_regen_timer: float = 0.0

@onready var nickname: Label3D = $PlayerNick/Nickname  

@export var move_speed = BASE_SPEED
@export var turn_speed = 10.0
@export var acceleration = 20
@export var gravity = 14.8

@export var player_model: Node3D
@export var camera_pivot: Node3D
@export var anim_player: AnimationPlayer
@export var camera: Camera3D

var is_jumping = false
var has_played_jump = false
var combat_stance = false
var combat_rotation = 0.0
var _respawn_point = Vector3(0, 5, 0)

# ✅ Position & Rotation for Network Sync
var network_position = Vector3.ZERO  # Stores last received position
var network_rotation = 0.0  # Stores last received rotation
@export var interpolation_speed = 10.0  # Speed for smoothing movement

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	camera.current = is_multiplayer_authority()

func _ready():
	print("Registered sync nodes: ", get_tree().get_nodes_in_group("multiplayer_synced"))
	if multiplayer.is_server():
		camera.current = false

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		handle_local_movement(delta)
		handle_resource_regen(delta)
		rpc_id(0, "update_position", position, player_model.rotation.y)
		var current_anim = anim_player.current_animation
		rpc_id(0, "sync_animation", current_anim)
	else:
		position = position.lerp(network_position, delta * interpolation_speed)
		player_model.rotation.y = lerp_angle(player_model.rotation.y, network_rotation, delta * 5.0)

	_check_fall_and_respawn()
	move_and_slide()

func _check_fall_and_respawn():
	if global_transform.origin.y < -15.0:
		_respawn()

func handle_resource_regen(delta: float):
	mana = min(max_mana, mana + mana_regen_rate * delta)
	if stamina < max_stamina:
		if stamina_regen_timer > 0:
			stamina_regen_timer -= delta
		else:
			stamina = min(max_stamina, stamina + stamina_regen_rate * delta)

@rpc("any_peer", "unreliable")
func sync_animation(anim_name: String):
	if not is_multiplayer_authority():
		_play_animation(anim_name)

func handle_local_movement(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
		if not has_played_jump:
			has_played_jump = true
			_play_animation("player/jump_start")
		elif anim_player.current_animation != "player/jump_start":
			_play_animation("player/falling")

	move_speed = SPRINT_SPEED if Input.is_action_pressed("sprint") and not combat_stance and stamina > 0 else BASE_SPEED
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_jumping = true
		has_played_jump = false
		velocity.y = JUMP_VELOCITY
		_play_animation("player/jump_start")
	
	if move_speed == SPRINT_SPEED:
		stamina = max(0, stamina - stamina_drain_sprint * delta)
		stamina_regen_timer = stamina_regen_delay
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var camera_basis = camera_pivot.global_transform.basis
	var move_dir = (camera_basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
	move_dir.y = 0
	move_dir = move_dir.normalized()

	var current_acceleration = acceleration
	if not is_on_floor():
		current_acceleration *= AIR_CONTROL

	if move_dir.length() > 0.01:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed

		var target_rotation = atan2(-move_dir.x, -move_dir.z)
		player_model.rotation.y = lerp_angle(player_model.rotation.y, target_rotation, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)

	apply_rotation(velocity)
	animate(velocity)

func _respawn():
	global_transform.origin = _respawn_point
	velocity = Vector3.ZERO
	health = max_health
	mana = max_mana
	stamina = max_stamina

func take_damage(amount: int):
	health = max(0, health - amount)
	if health == 0:
		_respawn()

func _play_animation(anim_name: String):
	if anim_player and anim_player.current_animation != anim_name:
		anim_player.play(anim_name, -1, 1.0)

# 🔄 **Smoothly rotates character based on velocity**
func apply_rotation(_velocity: Vector3) -> void:
	if _velocity.length() > 0.1:
		var new_rotation_y = lerp_angle(player_model.rotation.y, atan2(-_velocity.x, -_velocity.z), LERP_VELOCITY)
		player_model.rotation.y = new_rotation_y
		rpc("sync_player_rotation", new_rotation_y)

# 🎭 **Handles animation states based on movement & jumping**
func animate(_velocity: Vector3) -> void:
	if not is_on_floor():
		if _velocity.y < 0:
			_play_animation("player/falling")
		return

	if _velocity.length() > 0.1: 
		_play_animation("player/run" if move_speed == SPRINT_SPEED and is_on_floor() else "player/jog")
		return
	
	_play_animation("player/idle")

# 📡 Multiplayer sync for player rotation
@rpc("any_peer", "reliable")
func sync_player_rotation(rotation_y: float):
	player_model.rotation.y = rotation_y
	
# 📡 **Multiplayer Sync for Position & Rotation**
@rpc("authority", "unreliable")
func update_position(pos: Vector3, rot: float):
	if not is_multiplayer_authority():
		network_position = pos  # Update latest position
		network_rotation = rot  # Update latest rotation

# 📡 **Nick & Skin Sync (Placeholder)**
@rpc("any_peer", "reliable")
func change_nick(new_nick: String):
	if nickname:
		nickname.text = new_nick
