extends RefCounted
class_name Grounding3D

func compute_slope_degrees(floor_normal: Vector3) -> float:
	return rad_to_deg(acos(clamp(floor_normal.dot(Vector3.UP), -1.0, 1.0)))
	
func project_on_floor(vel: Vector3, floor_normal: Vector3) -> Vector3:
	return vel.slide(floor_normal)
	
func try_step_offset(_body: CharacterBody3D, _step_height: float, _mask: int) -> bool:
	return false
	
func should_treat_as_airborne(slope_deg: float, floor_max_deg: float) -> bool:
	return slope_deg > floor_max_deg
