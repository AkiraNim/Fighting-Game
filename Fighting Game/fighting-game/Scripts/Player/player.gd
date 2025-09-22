extends CharacterBody3D

@export var speed := 2.0
@export var sprite: AnimatedSprite3D  # PlayerSprite

var facing_right := true

func _ready():
	if sprite == null:
		sprite = $PlayerSprite

func _physics_process(_delta):
	handle_input()
	move_character()
	update_animation()
	update_facing()

func handle_input():
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_vector = input_vector.normalized()
	
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var direction = (forward * input_vector.y + right * input_vector.x).normalized()
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0

func move_character():
	move_and_slide()

func update_animation():
	if velocity.length() < 0.1:
		sprite.play("idle")
	else:
		sprite.play("walk")

func update_facing():
	# Apenas espelhar scale.x, pois Billboard sempre olha para a câmera
	if velocity.x > 0 and not facing_right:
		facing_right = true
		sprite.scale.x = abs(sprite.scale.x)
	elif velocity.x < 0 and facing_right:
		facing_right = false
		sprite.scale.x = -abs(sprite.scale.x)
