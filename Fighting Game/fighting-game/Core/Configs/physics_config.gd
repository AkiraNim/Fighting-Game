extends Resource
class_name PhysicsConfig

@export var gravity: float = 24.0
@export var walk_speed: float = 6.0
@export var run_speed: float = 7.5
@export var accel: float = 30.0
@export var decel: float = 40.0
@export var air_control_multiplier: float = 0.5

@export var jump_speed: float = 8.0
@export var coyote_time: float = 0.08
@export var jump_buffer: float = 0.12
@export var max_fall_speed: float = 60.0

@export var floor_max_angle_deg: float = 46.0
@export var snap_distance: float = 0.3
@export var step_height: float = 0.5
@export var step_max_slope_deg: float = 55.0

@export var world_mask: int = 1
@export var ground_probe_mask: int = 1
