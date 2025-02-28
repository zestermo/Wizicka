extends Node3D

@export var sensitivity = 0.3
@export var zoom_speed = 2.0
@export var min_zoom = 2.0
@export var max_zoom = 8.0
@export var camera_distance = 4.0

var rotation_x = 0.0
var rotation_y = 0.0

func _ready():
	# Capture mouse so you can rotate freely
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		# Yaw (left/right orbit)
		rotation_y -= event.relative.x * sensitivity

		# Pitch (up/down orbit).
		#   If you want the other direction, just flip the +/- here.
		#   This is "inverted style": mouse up tilts camera down
		rotation_x = clamp(rotation_x + (event.relative.y * sensitivity), -70, 70)

	if event is InputEventMouseButton and event.pressed:
		# Numeric codes 4/5 if MouseButton.WHEEL_UP / WHEEL_DOWN aren't recognized.
		if event.button_index == 4: # Wheel up
			camera_distance = max(camera_distance - zoom_speed, min_zoom)
		elif event.button_index == 5: # Wheel down
			camera_distance = min(camera_distance + zoom_speed, max_zoom)

func _process(delta):
	# Rotate pivot on X (pitch) & Y (yaw)
	rotation_degrees.x = rotation_x
	rotation_degrees.y = rotation_y

	# Position camera behind pivot
	$Camera3D.transform.origin = Vector3(0, 0, -camera_distance)
