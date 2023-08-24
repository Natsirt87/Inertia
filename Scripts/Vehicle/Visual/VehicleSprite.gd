class_name VehicleSprite
extends Sprite2D

@export var rotate_speed : float

var angle_x = 0
var angle_y = 0
var angle_limit_x = 0.35                                      
var angle_limit_y = 0.1
var rotating_up_x = true
var rotating_up_y = true

# TODO: Figure out how to imitate rotation of the sprite on X and Y axis (I know it's possible)
func _process(delta):
	rotate_x(delta)
	#rotate_y(delta)
	
	set_skew((sin(angle_x) / 8) + (sin(angle_y) / 12))

func rotate_x(delta):
	if (rotating_up_x):
		angle_x += rotate_speed * delta
		if (angle_x >= angle_limit_x):
			rotating_up_x = false;
	else:
		angle_x -= rotate_speed * delta;
		if (angle_x <= -angle_limit_x):
			rotating_up_x = true
	
	scale.x = cos(angle_x)
	
	rotation = -(sin(angle_x) / 8)

func rotate_y(delta):
	if (rotating_up_y):
		angle_y += rotate_speed * delta
		if (angle_y >= angle_limit_y):
			rotating_up_y = false
	else:
		angle_y -= rotate_speed * delta
		if (angle_y <= -angle_limit_y):
			rotating_up_y = true
	
	scale.y = cos(angle_y)
