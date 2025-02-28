extends ColorRect

func _ready():
	if not is_multiplayer_authority():  # Only apply to the local player
		queue_free()  # Remove this effect for non-local players
		return

	var shader_material = material as ShaderMaterial
	if shader_material:
		var viewport_texture = get_viewport().get_texture()  # Get only this player's render texture

		# Pass screen size and unique viewport texture for this player
		shader_material.set_shader_parameter("VIEWPORT_SIZE", get_viewport().size)
		shader_material.set_shader_parameter("SCREEN_TEXTURE", viewport_texture)
	else:
		print("❌ ShaderMaterial not found on ColorRect!")
