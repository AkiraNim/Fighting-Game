extends Node

class_name KinematicAdapter

class MotionResult:
	var velocity: Vector3 = Vector3.ZERO
	var just_landed: bool = false
	var just_left_ground: bool = false
	var collision_count: int = 0
	var floor_normal: Vector3 = Vector3.UP

class SurfaceProbe:
	var hit: bool = false
	var normal: Vector3 = Vector3.UP
	var distance: float = 0.0
	var slope_degrees: float = 0.0
	
func set_body(_body: CharacterBody3D)-> void:
	return

func move(body: CharacterBody3D, velocity: Vector3, floor_max_angle: float, _dt: float)-> MotionResult:
	var res := MotionResult.new()
	if not is_instance_valid(body):
		return res
	
	body.velocity = velocity
	body.floor_max_angle = floor_max_angle
	body.move_and_slide()
	
	res.velocity = body.velocity
	res.collision_count = body.get_slide_collision_count()
	res.floor_normal = body.get_floor_normal()
	
	res.just_landed = body.is_on_floor() and body.get_last_motion().y <= 0.0
	return res

func is_on_floor(body: CharacterBody3D)-> bool:
	return is_instance_valid(body) and body.is_on_floor()

func get_floor_normal(body: CharacterBody3D)-> Vector3:
	return body.get_floor_normal() if is_instance_valid(body) else Vector3.UP

func snap_to_floor(body: CharacterBody3D, max_snap_dist: float, floor_max_angle: float)-> bool:
	return false

func raycast_down(body: CharacterBody3D, dist: float, mask: int)-> SurfaceProbe:
	var p := SurfaceProbe.new()
	if not is_instance_valid(body):
		return p
	
	var space := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(body.global_transform.origin, body.global_transform.origin - Vector3.UP * dist, mask)
	var hit := space.intersect_ray(query)
	if hit.size() > 0:
		p.hit = true
		p.normal = hit.get("normal", Vector3.UP)
		p.distance = (hit.get("position", body.global_transform.origin) - body.global_transform.origin).length()
		p.slope_degrees = rad_to_deg(acos(clamp(p.normal.dot(Vector3.UP), -1.0, 1.0)))
	return p
