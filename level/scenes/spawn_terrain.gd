extends Node3D

@export var tree_scene: PackedScene  # Assign tree1.tscn in the Inspector
@export var terrain_mesh: MeshInstance3D  # Assign the MeshInstance3D that holds the terrain
@export var spawn_count: int = 50  # Number of trees to spawn
@export var spawn_area_size: Vector3 = Vector3(50, 0, 50)  # XZ range for random spawning
@export var raycast_height: float = 50.0  # Height from which to cast rays down

func _ready():
	if not tree_scene:
		push_error("No tree scene assigned!")
		return
	if not terrain_mesh:
		push_error("No terrain_mesh (MeshInstance3D) assigned!")
		return

	_spawn_trees()

func _spawn_trees():
	var world = get_world_3d().direct_space_state

	for i in range(spawn_count):
		var random_x = randf_range(-spawn_area_size.x, spawn_area_size.x)
		var random_z = randf_range(-spawn_area_size.z, spawn_area_size.z)
		var ray_origin = Vector3(random_x, raycast_height, random_z)  # Start ray above terrain
		var ray_target = Vector3(random_x, -raycast_height, random_z)  # Ray goes down

		# 🔥 Use terrain_mesh's collision layer for raycasting
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.collide_with_bodies = true  # Ensure it detects terrain mesh
		query.collide_with_areas = false  # Ignore areas
		query.collision_mask = terrain_mesh.collision_layer  # Use the mesh's collision layer

		var result = world.intersect_ray(query)

		if result:
			var hit_position = result.position  # Where the ray hits terrain
			var terrain_normal = result.normal  # The surface normal of terrain

			# 🌿 Spawn tree at correct height
			var tree_instance = tree_scene.instantiate()
			tree_instance.position = hit_position

			# 🌲 Align tree to terrain slope
			tree_instance.look_at(hit_position + terrain_normal, Vector3.UP)

			# Add to scene
			print("placing tree")
			add_child(tree_instance)
