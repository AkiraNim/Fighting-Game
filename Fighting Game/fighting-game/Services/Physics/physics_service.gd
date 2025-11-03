extends Node

signal actor_moved(actor: Node, pos: Vector3, vel: Vector3, speed: float)
signal actor_landed(actor: Node, floor_normal: Vector3, impact_speed: float)
signal actor_airborne(actor: Node)
signal actor_jumped(actor: Node)

var _adapter := KinematicAdapter.new()
var _grounding := Grounding3D.new()

@export var config: PhysicsConfig

class CharacterState:
	var grounded: bool = false
	var velocity: Vector3 = Vector3.ZERO
	var speed: float = 0.0
	var floor_normal: Vector3 = Vector3.UP
	var slope_angle_deg: float = 0.0
	var just_landed: bool = false
	var just_left_ground: bool = false
	var want_jump: bool = false
	var jump_buffer_ms: int = 0
	var coyote_ms_left: int = 0
	var jumping_up_ms: int = 0            
	var jump_button_held: bool = false
	var knockback_time_left: float = 0.0
	var external_force: Vector3 = Vector3.ZERO
	
	

var _bodies: = {}         
var _states: = {}        

var _time_scale: float = 1.0
var _hitstop: bool = false

func _ready() -> void:
	if config == null:
		push_warning("[PhysicsService] Not associated Config.")

func configure(cfg: PhysicsConfig) -> void:
	config = cfg

func register_actor(id: Node, body: CharacterBody3D, _kind: String = "actor") -> void:
	_bodies[id] = body
	_states[id] = CharacterState.new()

func unregister_actor(id: Node) -> void:
	_bodies.erase(id)
	_states.erase(id)

func set_time_scale(scale: float) -> void:
	_time_scale = max(0.0, scale)

func set_hitstop(enabled: bool) -> void:
	_hitstop = enabled

func get_state(id: Node) -> CharacterState:
	return _states.get(id, null)

func is_grounded(id: Node) -> bool:
	var st = _states.get(id, null)
	return st != null and st.grounded

func get_floor_normal(id: Node) -> Vector3:
	var st = _states.get(id, null)
	return st.floor_normal if st != null else Vector3.UP

func jump_request(id: Node) -> void:
	var st = _states.get(id, null)
	if st == null or config == null:
		return
	st.jump_buffer_ms = _sec_to_ms(config.jump_buffer)
	st.want_jump = true
	st.jump_button_held = true

func jump_release(id: Node) -> void:
	var st = _states.get(id, null)
	if st == null or config == null:
		return
	st.jump_button_held = false
	if st.velocity.y > 0.0 and st.jumping_up_ms >= _sec_to_ms(config.min_jump_uptime):
		st.velocity.y = min(st.velocity.y, st.velocity.y * config.jump_release_cut)
		
func apply_knockback(id: Node, force: Vector3, duration: float, _decay: float = 0.0) -> void:
	var st = _states.get(id, null)
	if st == null: return
	st.velocity += force
	st.knockback_time_left = duration

func apply_external_force(id: Node, force: Vector3, ttl: float) -> void:
	var st = _states.get(id, null)
	if st == null: return
	st.external_force += force

func tick_character(id: Node, intent_xz: Vector2, dt: float) -> CharacterState:
	if _hitstop or _time_scale <= 0.0:
		return _states.get(id, null)
	var body: CharacterBody3D = _bodies.get(id, null)
	var st: CharacterState = _states.get(id, null)
	if body == null or st == null or config == null:
		return st

	dt *= _time_scale
	var dt_ms := int(dt * 1000.0)
	var was_grounded := _adapter.is_on_floor(body)
	var floor_normal := _adapter.get_floor_normal(body)
	var slope_deg := _grounding.compute_slope_degrees(floor_normal)
	var target_speed := config.walk_speed
	var target_vxz := Vector2(intent_xz.x, intent_xz.y) * target_speed
	var curr_vxz := Vector2(st.velocity.x, st.velocity.z)
	var acc := config.accel
	var dec := config.decel
	
	st = _states.get(id, null) # (já temos, mas reafirmando escopo)
	if was_grounded:
		# Recarrega coyote e zera uptime de subida
		st.coyote_ms_left = _sec_to_ms(config.coyote_time)
		st.jumping_up_ms = 0
	else:
		st.coyote_ms_left = max(0, st.coyote_ms_left - dt_ms)
		
	if st.jump_buffer_ms > 0:
		st.jump_buffer_ms = max(0, st.jump_buffer_ms - dt_ms)
		
	if not was_grounded:
		acc *= config.air_control_multiplier
		dec *= config.air_control_multiplier
	var diff_len := (Vector2(target_vxz.x, target_vxz.y) - curr_vxz).length()
	if diff_len > 0.001:
		var t = clamp((acc if target_vxz.length() > curr_vxz.length() else dec) * dt / max(0.001, target_speed), 0.0, 1.0)
		curr_vxz = curr_vxz.lerp(target_vxz, t)
	else:
		curr_vxz = target_vxz
	st.velocity.x = curr_vxz.x
	st.velocity.z = curr_vxz.y
	
	if st.velocity.y > 0.0:
		st.jumping_up_ms += dt_ms
	else:
		st.jumping_up_ms = 0

	if not was_grounded:
		st.velocity.y = max(st.velocity.y - config.gravity * dt, -config.max_fall_speed)
	else:
		if st.velocity.y < 0.0:
			st.velocity.y = 0.0
	
	var can_jump_now := was_grounded or (st.coyote_ms_left > 0)
	if st.jump_buffer_ms > 0 and can_jump_now:
		st.velocity.y = config.jump_speed
		st.jump_buffer_ms = 0
		st.coyote_ms_left = 0
		st.jumping_up_ms = 0
		st.want_jump = false
		emit_signal("actor_jumped", id)
		
	#if st.want_jump and (was_grounded or st.coyote_ms_left > 0):
		#st.velocity.y = config.jump_speed
		#st.want_jump = false
		#emit_signal("actor_jumped", id)
		
	if st.knockback_time_left > 0.0:
		st.knockback_time_left = max(0.0, st.knockback_time_left - dt)
	st.velocity += st.external_force * dt
	
	var motion := _adapter.move(body, st.velocity, deg_to_rad(config.floor_max_angle_deg), dt)
	var is_grounded_now := _adapter.is_on_floor(body)
	floor_normal = motion.floor_normal
	slope_deg = _grounding.compute_slope_degrees(floor_normal)
	
	st.grounded = is_grounded_now
	st.floor_normal = floor_normal
	st.slope_angle_deg = slope_deg
	st.velocity = motion.velocity
	st.speed = Vector2(st.velocity.x, st.velocity.z).length()
	
	if (not was_grounded) and is_grounded_now:
		emit_signal("actor_landed", id, floor_normal, abs(st.velocity.y))
	elif was_grounded and (not is_grounded_now):
		emit_signal("actor_airborne", id)
	
	emit_signal("actor_moved", id, body.global_transform.origin, st.velocity, st.speed)
	return st
	
func _sec_to_ms(s: float) -> int:
	return int(s * 1000.0)
