# WeaponAnimator.gd
extends Node3D

var bob_time: float = 0.0
var bob_amount = Vector2(0.01, 0.02)
var bob_speed = 10.0

func update_bob(velocity: Vector3, delta: float):
	var speed = velocity.length()
	
	if speed > 0.1:
		bob_time += delta * bob_speed
		
		position.x = cos(bob_time) * bob_amount.x
		position.y = abs(sin(bob_time)) * bob_amount.y
	else:
		position = position.lerp(Vector3.ZERO, 5.0 * delta)
