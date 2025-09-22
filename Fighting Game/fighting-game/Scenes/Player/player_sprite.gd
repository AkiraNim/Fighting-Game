extends AnimatedSprite3D

func _process(delta):
	if material_override and sprite_frames:
		var frame_tex = sprite_frames.get_frame_texture(animation, frame)
		material_override.set_shader_parameter("sprite_texture", frame_tex)
