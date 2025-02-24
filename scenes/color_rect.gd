extends ColorRect

func _ready():
	var shader_material = material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("VIEWPORT_SIZE", get_viewport().size)  # Pass screen size
		shader_material.set_shader_parameter("SCREEN_TEXTURE", get_viewport().get_texture())  # Set the main viewport texture
	else:
		print("❌ ShaderMaterial not found on ColorRect!")
