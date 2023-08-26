class_name VehicleSprite
extends Sprite2D

@export var rotate_speed : float
@export var max_lat_accel: float
@export var max_long_accel: float

var angle_x = 0.0
var angle_y = 0.0
var angle_limit_x = 0.35                                  
var angle_limit_y = 0.15
var rotating_up_x = true
var rotating_up_y = true

var vehicle: Vehicle

# TODO: Figure out how to imitate rotation of the sprite on X and Y axis (I know it's possible)
func _physics_process(delta):
	var long_accel = vehicle.acceleration.dot(vehicle._forward)
	var lat_accel = vehicle.acceleration.dot(vehicle._right)
	
	rotate_x(lat_accel / max_lat_accel * angle_limit_x, delta)
	rotate_y(long_accel / max_long_accel * angle_limit_y, delta)
	
	set_skew((sin(angle_x) / 8) + (sin(angle_y) / 12))

func rotate_x(target, delta):
	angle_x = lerp(angle_x, target, rotate_speed * delta)
	
	scale.x = cos(angle_x * 0.6)
	
	rotation = -(sin(angle_x) / 8)

func rotate_y(target, delta):
	angle_y = lerp(angle_y, target, rotate_speed * delta)
	scale.y = cos(angle_y)
