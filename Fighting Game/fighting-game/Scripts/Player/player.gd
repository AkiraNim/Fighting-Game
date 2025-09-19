extends CharacterBody3D

@export var speed := 2.0
@export var sprite: AnimatedSprite3D  # PlayerSprite

var facing_right := true

func _ready():
	if sprite == null:
		sprite = $PlayerSprite

func _physics_process(delta):
	handle_input()
	move_character()
	update_animation()

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

	if velocity.x > 0:
		facing_right = true
	elif velocity.x < 0:
		facing_right = false

func move_character():
	move_and_slide()

func update_animation():
	# Sprite principal
	if velocity.length() < 0.1:
		sprite.play("idle")
	else:
		sprite.play("walk")
	
	# Espelhamento do sprite principal
	var s = sprite.scale
	s.x = abs(s.x) if facing_right else -abs(s.x)
	sprite.scale = s

	# Atualiza PlayerShadow
	if sprite.has_node("PlayerShadow"):
		var shadow = sprite.get_node("PlayerShadow") as AnimatedSprite3D
		shadow.animation = sprite.animation
		shadow.frame = sprite.frame
		
		# Espelhamento X mantendo a rotação fixa
		var shadow_scale = shadow.scale
		shadow_scale.x = abs(shadow_scale.x) if facing_right else -abs(shadow_scale.x)
		shadow.scale = shadow_scale
