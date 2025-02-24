extends StaticBody3D

@export var heightmap_texture: Texture2D
@export var height_scale: float = 2.0  # Adjust based on how high your terrain should be

func _ready():
	if heightmap_texture == null:
		print("ERROR: Heightmap texture not assigned!")  # Debugging message
		return

	var image = heightmap_texture.get_image()
	
	if image == null:
		print("ERROR: Failed to load heightmap image!")
		return

	image.convert(Image.FORMAT_RF)  # Convert to grayscale heightmap
	var heightmap_data = image.get_data()

	var shape = HeightMapShape3D.new()
	shape.map_width = image.get_width()
	shape.map_depth = image.get_height()
	shape.map_data = heightmap_data
	shape.map_scale = height_scale  # Adjust height variation

	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

	print("✅ Heightmap collision applied successfully!")
