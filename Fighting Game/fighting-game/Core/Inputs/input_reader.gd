extends Node

signal command_emitted(event)

const MOVE_CHANGE_EPSILON := 0.02
const DEFAULT_DEVICE_KB := "kb"
const DEFAULT_DEVICE_MOUSE := "mouse"
const DEFAULT_DEADZONE := 0.18
const PAUSE_DEBOUNCE_MS := 180

var _last_move := Vector2.ZERO
var _last_pause_ms:= 0

func _ready()-> void:
	_last_move = Vector2.ZERO

func _physics_process(delta: float) -> void:
	#Input movement
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if abs(v.x) < DEFAULT_DEADZONE: v.x = 0.0
	if abs(v.y) < DEFAULT_DEADZONE: v.y = 0.0
	var move := Vector2(v.x, -v.y)
	if move.length() > 1.0:
		move = move.normalized()
	
	if (_last_move - move).length() >= MOVE_CHANGE_EPSILON or (move == Vector2.ZERO and _last_move != Vector2.ZERO):
		_emit_move(move, _guess_last_device_for_move())
		_last_move = move
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var now_ms := Time.get_ticks_msec()
		if now_ms - _last_pause_ms >= PAUSE_DEBOUNCE_MS:
			_emit_cmd({"type": "Pause", "state": "pressed", "value": null, "device_id": _device_id_from_event(event)})
			_last_pause_ms = now_ms
		
	#UI/Helpers
	if event.is_action_pressed("ui_up"):
		_emit_cmd({ "type":"MenuNav", "state":"pressed", "value":"up", "device_id": _device_id_from_event(event) })
		
	if event.is_action_pressed("ui_down"):
		_emit_cmd({ "type":"MenuNav", "state":"pressed", "value":"down", "device_id": _device_id_from_event(event) })
	
	if event.is_action_pressed("ui_left"):
		_emit_cmd({ "type":"MenuNav", "state":"pressed", "value":"left", "device_id": _device_id_from_event(event) })
	
	if event.is_action_pressed("ui_right"):
		_emit_cmd({ "type":"MenuNav", "state":"pressed", "value":"right", "device_id": _device_id_from_event(event) })
	
	if event.is_action_pressed("ui_accept"):
		_emit_cmd({ "type":"Accept", "state":"pressed", "value":null, "device_id": _device_id_from_event(event) })
	
	if event.is_action_pressed("ui_cancel"):
		_emit_cmd({ "type":"Cancel", "state":"pressed", "value":null, "device_id": _device_id_from_event(event) })
	
	#Combat Pressed
	if event.is_action_pressed("attack_light"):
		_emit_cmd({ "type":"Attack", "state":"pressed", "value":"light", "device_id": _device_id_from_event(event) })
	
	if event.is_action_pressed("attack_heavy"):
		_emit_cmd({ "type":"Attack", "state":"pressed", "value":"heavy", "device_id": _device_id_from_event(event) })
	
	if event.is_action_pressed("parry"):
		_emit_cmd({ "type":"Parry", "state":"pressed", "value":null, "device_id": _device_id_from_event(event) })
	
	if event.is_action_released("jump"):
		_emit_cmd({ "type":"Jump", "state":"pressed", "value": null, "device_id": _device_id_from_event(event) })
	
	#Combat Released
	if event.is_action_released("attack_light"):
		_emit_cmd({ "type":"Attack", "state":"released", "value":"light", "device_id": _device_id_from_event(event) })
	
	if event.is_action_released("attack_heavy"):
		_emit_cmd({ "type":"Attack", "state":"released", "value":"heavy", "device_id": _device_id_from_event(event) })
	
	if event.is_action_released("parry"):
		_emit_cmd({ "type":"Parry", "state":"released", "value": null, "device_id": _device_id_from_event(event) })
	
	if event.is_action_released("jump"):
		_emit_cmd({ "type":"Jump", "state":"released", "value": null, "device_id": _device_id_from_event(event) })
	

func _emit_move(v: Vector2, device_id: String) -> void:
	_emit_cmd({
	"type": "Move",
	"state": "axis",
	"value": v,                
	"device_id": device_id
	})

func _emit_cmd(payload: Dictionary) -> void:
	payload["timestamp_ms"] = Time.get_ticks_msec()
	if not payload.has("device_id"): payload["device_id"] = "kb"
	EventBus.command_emitted.emit(payload)

func _device_id_from_event(event: InputEvent) -> String:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return "gp%d" % event.device
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return "mouse"
	return "kb"

func _guess_last_device_for_move() -> String:
	return "gp0" if Input.get_connected_joypads().size() > 0 else "kb"
