extends MeshInstance3D

var t = 0.0

func _process(delta):
	t += delta
	if material_override:
		material_override.set_shader_parameter("time", t)
