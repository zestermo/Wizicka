extends Node3D

@export var terrain: Node # Assign your Terrainy node here
@export var max_terrain_height: float = 50.0 # Match Terrainy’s max height
@export var ray_length: float = 200.0 # Adjust as needed
@export var force_collision_update: bool = true # NEW: Force refresh Terrainy's collision

func _ready():
	find_terrain()
	if terrain:
		print("[DEBUG] Terrain assigned: ", terrain.name)
		# Connect to Terrainy's signal
		if terrain.has_signal("terrain_generation_finished"):
			print("[DEBUG] Waiting for Terrainy to finish generating...")
			terrain.terrain_generation_finished.connect(_on_terrain_generation_finished)
		else:
			print("[ERROR] Terrainy has no terrain_generation_finished signal! Adjusting immediately.")
			adjust_height() # If no signal, run immediately
	else:
		print("[ERROR] No terrain found in the scene! Buildings may float!")

func find_terrain():
	if terrain:
		return  # If already set, skip finding

	print("[DEBUG] Looking for Terrainy in the scene...")
	var terrains = get_tree().get_nodes_in_group("terrain")
	if terrains.size() > 0:
		terrain = terrains[0]  # Use the first terrain found
		print("[DEBUG] Auto-assigned Terrainy: ", terrain.name)
	else:
		print("[ERROR] No Terrainy node found!")

func _on_terrain_generation_finished():
	print("[DEBUG] Terrain generation complete! Waiting for collision update...")

	# Force collision refresh if needed
	if force_collision_update and terrain.has_method("create_surface") and terrain.terrain_meshes:
		print("[DEBUG] Forcing Terrainy collision refresh...")
		for mesh in terrain.terrain_meshes:
			print("[DEBUG] Refreshing collision for: ", mesh.name)
			terrain.create_surface(mesh)

	# Wait 5 frames to allow Terrainy to update its collision
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	print("[DEBUG] Proceeding with height adjustment!")
	adjust_height()

func adjust_height():
	print("[DEBUG] Adjusting height for ", name)

	var position = global_transform.origin
	var y = raycast_down(position)

	if y != null:
		print("[DEBUG] Moving ", name, " to Y:", y)
		global_transform.origin.y = y
	else:
		print("[ERROR] No terrain detected for ", name, "! Keeping original position.")

func raycast_down(start_pos: Vector3) -> float:
	var space = get_world_3d().direct_space_state
	var ray_start = start_pos + Vector3(0, ray_length, 0) # Cast from above
	var ray_end = start_pos + Vector3(0, -ray_length, 0) # Cast downward

	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result = space.intersect_ray(query)
	if result:
		print("[DEBUG] Raycast hit object: ", result.collider.name, " at Y:", result.position.y)
		return result.position.y

	print("[ERROR] Raycast failed! No terrain detected.")
	return 0.0
