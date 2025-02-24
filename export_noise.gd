extends Node

func _ready():
	export_noise_to_png()

func export_noise_to_png():
	var noise_texture = load("res://terrainNoise.tres")  # Replace with your actual .tres file
	if noise_texture == null:
		print("🚨 Error: Couldn't load noise texture!")
		return

	var noise = noise_texture.noise  # Get noise resource
	if noise == null:
		print("🚨 Error: No noise found in texture!")
		return

	var size = 512  # Resolution of the image
	var scale = 5.0  # Increase for more visible patterns (try 5-20)
	
	var image = Image.create(size, size, false, Image.FORMAT_L8)  # Grayscale format

	for x in range(size):
		for y in range(size):
			var value = noise.get_noise_2d(x / float(size) * scale, y / float(size) * scale)  # Scale noise coords
			value = (value + 1.0) * 0.5  # Normalize from -1 to 1 → 0 to 1
			image.set_pixel(x, y, Color(value, value, value, 1))  # Grayscale pixel

	var save_path = "res://exported_terrain.png"
	image.save_png(save_path)  # Save as PNG
	print("✅ Noise exported successfully to:", save_path)
