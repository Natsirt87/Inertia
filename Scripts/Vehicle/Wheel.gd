class_name Wheel
extends Area2D

# constants
var LOW_SPEED_THRESHOLD: float = 2.5
var COUNTER_STEER_GAIN: float = 1.2

# Export variables
@export var front: bool
@export var right: bool
@export var steering: bool
@export var max_steering_angle: float
@export var torque_ratio: float # Ratio of engine torque sent to this wheel
@export var max_friction: float = 1.1 # Maximum tire friction coefficient, not sliding
@export var min_friction: float = 0.8 # Minimum tire friction coefficient, maximum slip
@export var traction_falloff: float = 2 # How quickly traction falls of, higher number = slower
@export var traction_constant: float = 0.1666 # How much force is generated for slip ratio
@export var peak_tire_slip: float = 3 # How much force is generated for slip angle

# Public variables 
var slip_angle: float = 0

# Private variables
var _throttle_input: float = 0
var _brake_input: float = 0
var _steering_input: float = 0
var _vehicle: Vehicle

var _desired_force: Vector2 = Vector2.ZERO
var _traction_force: float = 0
var _cornering_force: float = 0
var _friction_coefficient: float = 0
var _last_position: Vector2
var _linear_velocity: Vector2 = Vector2.ZERO
var _last_velocity: Vector2 = Vector2.ZERO
var _linear_accel: Vector2 = Vector2.ZERO
var _wheel_offset: Vector2

var _last_slip_angle: float = 0

@onready var _forward: Vector2 = -global_transform.y.normalized()
@onready var _right: Vector2 = global_transform.x.normalized()

# Called when the node enters the scene tree for the first time.
func _ready():
	_friction_coefficient = max_friction
	_last_position = global_position

func _physics_process(delta):
	# Update unit vectors
	_forward = global_transform.basis_xform(Vector2.UP).normalized()
	_right = global_transform.basis_xform(Vector2.RIGHT).normalized()
	
	# Update linear velocity
	_linear_velocity = Utility.p_to_m((global_position - _last_position) / delta)
	_last_position = global_position
	
	# Update linear acceleration
	_linear_accel = (_linear_velocity - _last_velocity) / delta
	_last_velocity = _linear_velocity
	
	_wheel_offset = global_position - _vehicle.global_position
	
	_desired_force = Vector2(0, 0)
	
	var tire_load = _vehicle.mass * 0.25 * 9.81 # Total load (weight) pushing on the tire
	var max_force = max_friction * tire_load # Maximum possible force the tire could exert
	var available_force = _friction_coefficient * tire_load # Available force in current conditions
	
	if _vehicle:
		if steering:
			_steer(delta)
		if torque_ratio > 0:
			_drive(available_force)
		_lateral_forces(max_force, delta)
		_brake(max_force)
	
	# Calculate the actual applied force
	var applied_force: Vector2
	# Determine if the grip of the tire is being exceeded, and change the friction accordingly
	if _desired_force.length() > available_force:
		_friction_coefficient = min_friction
		
		# Tire is exceeding maximum grip, so applied force must be adjusted
		applied_force = _desired_force.normalized() * tire_load * _friction_coefficient
	else:
		_friction_coefficient = max_friction
		applied_force = _desired_force
	
	# Apply the net wheel force to the vehicle
	_vehicle.apply_wheel_force(applied_force, _wheel_offset)

func _get_sliding_friction(desired, max):
	if (desired <= max):
		return desired
	
	var input = (desired / max) - 1
	var friction = 1 - ((1 - min_friction) / traction_falloff) * input
	return friction

func _steer(delta):
	var speed = _linear_velocity.dot(_forward)
	# Low speed steering to avoid instability
	if abs(speed) < LOW_SPEED_THRESHOLD:
		var desired_angle = _steering_input * max_steering_angle
		var steering_angle = lerp(rotation_degrees, desired_angle, _vehicle.steering_speed * delta * 0.1)

		rotation_degrees = steering_angle

	# Reverse steering 
	elif speed < 0:
		var desired_angle = _steering_input * max_steering_angle
		var B = 2
		var C = 5
		var speed_sens = 1 * B/ ((_linear_velocity.length() - LOW_SPEED_THRESHOLD + 1) * C)
		var steering_angle = lerp(rotation_degrees, desired_angle, _vehicle.steering_speed * delta * speed_sens)

		rotation_degrees = steering_angle

	# Forward steering
	else:
		var steering_angle = rotation_degrees
		var desired_slip_angle = (_steering_input * (peak_tire_slip - 0.2))

		var counter_steer = 0.3
		var counter_steer_sensitivity = 1
		
		var speed_sens = _vehicle.speed_sensitivity.sample(abs(speed) / 100)
		
		if _vehicle.oversteering:
			var neutral_v_lat = _linear_velocity.dot(_vehicle._right)
			var neutral_v_long = _linear_velocity.dot(_vehicle._forward)
			var neutral_slip_angle = rad_to_deg(-atan2(neutral_v_lat, neutral_v_long))
#			if (sign(desired_slip_angle) != sign(neutral_slip_angle)):
#				desired_slip_angle *= COUNTER_STEER_GAIN
			desired_slip_angle *= COUNTER_STEER_GAIN
			desired_slip_angle += neutral_slip_angle * counter_steer
			
			counter_steer_sensitivity *= 3
		
		var p_gain = _vehicle.steering_speed * speed_sens * delta * counter_steer_sensitivity
		var d_gain = 0.02 * delta
		
		var error = desired_slip_angle - slip_angle
		var p = p_gain * error
		
		var value_delta = (slip_angle - _last_slip_angle) / delta
		_last_slip_angle = slip_angle
		var d = d_gain * -value_delta
		
		steering_angle += p + d
		
		rotation_degrees = clamp(steering_angle, -max_steering_angle, max_steering_angle)


func _lateral_forces(max_force, delta):
	var lateral_velocity = _linear_velocity.dot(_right)
	var longitudinal_velocity = _linear_velocity.dot(_forward)
	
	if longitudinal_velocity > LOW_SPEED_THRESHOLD:
		slip_angle = rad_to_deg(-atan2(lateral_velocity, longitudinal_velocity))
	else:
		var max_slip_angle = 15.0
		var low_speed_slip = rad_to_deg(-atan2(lateral_velocity, LOW_SPEED_THRESHOLD))
		slip_angle = clamp(low_speed_slip, -max_slip_angle, max_slip_angle)
	
	var lateral_force = slip_angle * (1 / peak_tire_slip) * _right * max_force
	_desired_force += lateral_force
	
func _drive(max_force):
	# simple temporary approximation of driven wheel force
	var max_drive_force = torque_ratio * _vehicle.engine_force
	var drive_force = _forward * _throttle_input * max_drive_force
	
	_desired_force += drive_force

func _brake(available_force):
	var remaining_force = clamp(available_force - _desired_force.length(), 0, available_force)
	var max_braking_force = remaining_force * 0.99
	var brake_force_magnitude = _brake_input * max_braking_force
	var brake_force = -_linear_velocity.normalized() * brake_force_magnitude
	#var brake_force = -sign(_linear_velocity.normalized().dot(_forward)) * brake_force_magnitude * _forward
	_desired_force += brake_force

# Public functions
func set_throttle_input(input: float):
	_throttle_input = input

func set_steering_input(input: float):
	_steering_input = (input)

func set_brake_input(input: float):
	_brake_input = input

func set_vehicle(vehicle):
	_vehicle = vehicle
