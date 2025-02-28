extends Node3D

# 🦵 Foot IK Variables (Drag & Drop in Inspector)
@export var left_foot_target: Node3D
@export var right_foot_target: Node3D

@export var left_raycast: RayCast3D
@export var right_raycast: RayCast3D

@export var left_skeleton_ik: SkeletonIK3D
@export var right_skeleton_ik: SkeletonIK3D

# ✊ Combat Stance (Hand IK)
@export var left_hand_ik: SkeletonIK3D
@export var right_hand_ik: SkeletonIK3D

@export var torso_ik: SkeletonIK3D

@export var reticle: Control  # UI reticle (Hidden when not in combat stance)

# 🔧 IK Settings (Tweak in Inspector)
@export var foot_offset: float = 0.1  # Prevents feet sinking into the ground
@export var ik_blend_speed: float = 5.0  # IK transition speed for feet
@export var combat_ik_blend_speed: float = 5.0  # IK transition speed for hands

var left_ik_weight := 0.0  # IK blend factor for left foot
var right_ik_weight := 0.0  # IK blend factor for right foot
var combat_ik_weight := 0.0  # IK blend factor for combat stance

var combat_mode := false  # Combat stance toggle

func _ready():
	# Start IK for feet
	if left_skeleton_ik:
		left_skeleton_ik.start()
	if right_skeleton_ik:
		right_skeleton_ik.start()

	# Make sure hand IK is disabled at the start
	if left_hand_ik:
		left_hand_ik.start()
		left_hand_ik.interpolation = 0.0
	if right_hand_ik:
		right_hand_ik.start()
		right_hand_ik.interpolation = 0.0
	if torso_ik:
		torso_ik.start()
		torso_ik.interpolation = 0.0
	
	# Hide reticle at start
	if reticle:
		reticle.hide()

func _input(event):
	if event.is_action_pressed("spell_cast_mode"):
		combat_mode = !combat_mode  # Toggle combat mode

		# Show/hide reticle based on stance
		if reticle:
			if combat_mode:
				reticle.show()
			else:
				reticle.hide()

func _process(delta):
	# 🌱 FOOT IK - Adjust ground placement
	if left_raycast and left_foot_target:
		adjust_foot_position(left_raycast, left_foot_target)
	
	if right_raycast and right_foot_target:
		adjust_foot_position(right_raycast, right_foot_target)

	# Smoothly blend IK weight based on ground contact
	var left_target_weight = 1.0 if left_raycast.is_colliding() else 0.0
	var right_target_weight = 1.0 if right_raycast.is_colliding() else 0.0

	left_ik_weight = lerp(left_ik_weight, left_target_weight, delta * ik_blend_speed)
	right_ik_weight = lerp(right_ik_weight, right_target_weight, delta * ik_blend_speed)

	if left_skeleton_ik:
		left_skeleton_ik.interpolation = left_ik_weight
	if right_skeleton_ik:
		right_skeleton_ik.interpolation = right_ik_weight

	# ✊ COMBAT IK - Enable/disable hand IK
	var combat_target_weight = 1.0 if combat_mode else 0.0
	combat_ik_weight = lerp(combat_ik_weight, combat_target_weight, delta * combat_ik_blend_speed)

	if left_hand_ik:
		left_hand_ik.interpolation = combat_ik_weight
	if right_hand_ik:
		right_hand_ik.interpolation = combat_ik_weight
	if torso_ik:
		torso_ik.interpolation = combat_ik_weight

func adjust_foot_position(raycast: RayCast3D, foot_target: Node3D):
	if raycast.is_colliding():
		var ground_pos = raycast.get_collision_point()
		foot_target.global_position.y = ground_pos.y + foot_offset
