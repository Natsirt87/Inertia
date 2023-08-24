class_name Vehicle
extends RigidBody2D

# Exports
@export var steering_speed : float
@export var engine_force : float
@export var wheelbase : float
@export var track_width : float
@export var cg_height : float
@export var speed_sensitivity : Curve

# Public variables
var acceleration : Vector2
var angular_accel : float
var oversteering : bool

# Private variables
var _last_velocity : Vector2
var _last_angular_velocity : float
var _throttle_input : float = 0
var _front_wheels : Array
var _rear_wheels : Array

# On ready variables
@onready var _forward : Vector2 = -global_transform.y.normalized()
@onready var _right : Vector2 = global_transform.x.normalized()
@onready var _wheels : Array = $Body/VehicleSprite/Wheels.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	for wheel in _wheels:
		wheel.set_vehicle(self)
		if wheel.front:
			_front_wheels.append(wheel)
		else:
			_rear_wheels.append(wheel)

func _physics_process(delta):
	# Update unit vectors
	_forward = -global_transform.y.normalized()
	_right = global_transform.x.normalized()
	
	# Calculate acceleration in m/s^2
	acceleration = Utility.p_to_m( (linear_velocity - _last_velocity) / delta )
	#print("Accel: " + str(acceleration) + "Speed (mph): " + str(Utility.ps_to_mph(linear_velocity.length())))
	
	angular_accel = (angular_velocity - _last_angular_velocity) / delta
	
	_last_velocity = linear_velocity
	_last_angular_velocity = angular_velocity
	_determine_oversteer()

func _determine_oversteer():
	var steer_dir = sign(_front_wheels[0].rotation_degrees)
	# Get outside rear tire
	var rear = _rear_wheels[0] if steer_dir > 0 else _rear_wheels[0]
	
	# If the rear outside tire's slip angle is exceeding the max, the car is oversteering
	oversteering = true if abs(rear.slip_angle) > (rear.peak_tire_slip + 1) else false

func set_throttle_input(input : float):
	_throttle_input = input
	for wheel in _wheels:
		wheel.set_throttle_input(input)

func set_steering_input(input : float):
	var steering_input = (input)
#	var speed_ratio = Utility.p_to_m(linear_velocity.length()) / 100
#	steering_input *= speed_sensitivity.sample(speed_ratio)
	for wheel in _wheels:
		wheel.set_steering_input(steering_input)

func set_brake_input(input : float):
	var brake_input = input
	for wheel in _wheels:
		wheel.set_brake_input(brake_input)
		
func apply_central_wheel_force(force : Vector2):
	apply_central_force(Vector2(Utility.n_to_f(force.x), Utility.n_to_f(force.y)))

func apply_wheel_force(force : Vector2, offset : Vector2):
	apply_force(Vector2(Utility.n_to_f(force.x), Utility.n_to_f(force.y)), offset)

func apply_wheel_torque(torque : float):
	apply_torque(Utility.nm_to_fp(torque))