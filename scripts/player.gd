extends CharacterBody3D

@export var move_speed := 3.5
@export var acceleration := 18.0
@export var deceleration := 24.0

var facing := Vector3.FORWARD
var walk_time := 0.0
var visual: Sprite3D


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0
	input_vector = input_vector.limit_length(1.0)
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var target_velocity := direction * move_speed
	var ramp := acceleration if direction.length_squared() > 0.001 else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, ramp * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, ramp * delta)
	velocity.y = 0.0
	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length_squared() > 0.02
	if moving:
		facing = Vector3(velocity.x, 0.0, velocity.z).normalized()
		walk_time += delta * 9.0
	else:
		walk_time = 0.0

	if visual:
		var bob := sin(walk_time) * 0.025 if moving else 0.0
		visual.position.y = 0.78 + bob
