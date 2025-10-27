extends AnimatedSprite3D

var facing_right := true

func _process(_delta):
	if material_override and sprite_frames:
		var frame_tex = sprite_frames.get_frame_texture(animation, frame)
		material_override.set_shader_parameter("sprite_texture", frame_tex)
		material_override.set_shader_parameter("facing_right", facing_right)
