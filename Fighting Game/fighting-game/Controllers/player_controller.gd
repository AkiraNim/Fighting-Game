extends CharacterBody3D
class_name PlayerController3D

var move_input: Vector2 = Vector2.ZERO

@export var listen_pause: bool = true

func _ready() -> void:
	EventBus.command_emitted.connect(_on_command)
	PhysicsService.register_actor(self, self)
	PhysicsService.actor_moved.connect(_on_actor_moved)

func _exit_tree() -> void:
	if EventBus.command_emitted.is_connected(_on_command):
		EventBus.command_emitted.disconnect(_on_command)
	if PhysicsService.actor_moved.is_connected(_on_actor_moved):
		PhysicsService.actor_moved.disconnect(_on_actor_moved)
		PhysicsService.unregister_actor(self)

func _physics_process(delta: float) -> void:
	var st = PhysicsService.tick_character(self, move_input, delta)

func _on_command(event: Dictionary) -> void:
	match event.get("type", ""):
		"Move":

			move_input = event.get("value", Vector2.ZERO)

		"Jump":
			var s = event.get("state", "")
			if s == "pressed":
				PhysicsService.jump_request(self)   
			elif s == "released":
				PhysicsService.jump_release(self)   

		"Pause":
			if listen_pause and event.get("state","") == "pressed":
				get_tree().paused = not get_tree().paused
				EventBus.pause_toggled.emit(get_tree().paused)

		_:
			pass

func _on_actor_moved(actor: Node, pos: Vector3, vel: Vector3, speed: float) -> void:
	if actor == self:
		EventBus.command_emitted.emit({
		"type": "PlayerMoved",
		"state": "tick",
		"value": { "position": pos, "velocity": vel, "speed": speed },
		"device_id": "",
		"timestamp_ms": Time.get_ticks_msec()
		})
