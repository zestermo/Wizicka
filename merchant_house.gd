extends RigidBody3D

@export var stop_on_collision: bool = true # Stop moving when it touches the ground?

func _ready():
	print("[DEBUG] Gravity applied, buildings will drop naturally!")
	contact_monitor = true  # Enable collision detection
	max_contacts_reported = 1  # Only detect the first collision

func _physics_process(delta):
	if stop_on_collision and get_contact_count() > 0:
		print("[DEBUG] Building landed on terrain!")
		freeze = true  # Stop physics movement
		contact_monitor = false  # Disable further contact checks
		set_collision_layer_value(1, false)  # Optional: Disable collision after landing
