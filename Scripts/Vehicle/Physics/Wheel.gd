class_name Wheel
extends Area2D

# constants
var LOW_SPEED_THRESHOLD: float = 2.5
var COUNTER_STEER_GAIN: float = 1.2
var COUNTER_STEER_SPEED: float = 0.1
var CENTERING_SPEED: float = 0.08
var STEERING_FORCE: float = 60
var STEERING_DERIVATIVE: float = 0.1
var SLIP_RATIO_RELAXATION: float = 0.091

# Export variables
@export var front: bool
@export var left: bool
@export var steering: bool
@export var max_steering_angle: float
@export var tire_model: Tire
@export var max_friction: float = 1.1 # Maximum tire friction coefficient, not sliding
@export var min_friction: float = 0.8 # Minimum tire friction coefficient, maximum slip
@export var radius: float = 30 # Effective radius of the tire
@export var mass: float = 70 #mass of the wheel & tire

# Public variables 
var slip_angle: float = 0
var slip_ratio: float = 0
var tire_load: float = 0
var linear_velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0
var linear_accel: Vector2 = Vector2.ZERO

# Private variables
var _brake_input: float = 0
var _steering_input: float = 0
var _drive_torque: float = 0
var _vehicle: Vehicle
var _total_torque: float = 0
var _last_position: Vector2
var _last_velocity: Vector2 = Vector2.ZERO
var _wheel_offset: Vector2
var _last_slip_angle: float = 0
var _diff_slip_ratio: float = 0

@onready var forward: Vector2 = -global_transform.y.normalized()
@onready var right: Vector2 = global_transform.x.normalized()

# Called when the node enters the scene tree for the first time.
func _ready():
	_last_position = global_position

func _update_properties(delta):
	# Update unit vectors
	forward = global_transform.basis_xform(Vector2.UP).normalized()
	right = global_transform.basis_xform(Vector2.RIGHT).normalized()
	
	# Update linear velocity
	linear_velocity = Utility.p_to_m((global_position - _last_position) / delta)
	_last_position = global_position
	
	# Update linear acceleration
	linear_accel = (linear_velocity - _last_velocity) / delta
	_last_velocity = linear_velocity
	
	_wheel_offset = global_position - _vehicle.global_position
	
	_total_torque = 0

func _physics_process(delta):
	_update_properties(delta)
	
	if _vehicle:
		if steering:
			_steer(delta)
	
		_longitudinal_forces(delta)
		_lateral_forces(delta)
		#_brake(max_force)
	
	# Calculate the actual applied force
	tire_load = _get_tire_load() # Total load (weight) pushing on the tire
	var applied_force
	var surface = tire_model.Surface.DRY 
	applied_force = tire_model.compute_force(slip_ratio, slip_angle, tire_load, surface, forward, right)
	
	# Apply the traction torque to the wheel (torque from road on tire, opposing rotation)
	var long_force = applied_force.dot(forward)
	var traction_torque = long_force * radius
	_total_torque -= traction_torque
	
	# Update angular velocity of the wheel based on torque
	_update_angular_velocity(delta)

	# Apply the net wheel force to the vehicle
	_vehicle.apply_wheel_force(applied_force, _wheel_offset)

func _update_angular_velocity(delta):
	var inertia = mass * radius * radius / 2
	var ang_accel = _total_torque / inertia
	angular_velocity += ang_accel * delta

func _get_tire_load():
	var opp_axle_distance = _vehicle.rear_axle_dist if front else _vehicle.front_axle_dist
	var weight = _vehicle.mass * 9.81
	
	var long_accel = _vehicle.linear_accel.dot(_vehicle.forward)
	var lat_accel = _vehicle.linear_accel.dot(_vehicle.right)
	
	var stationary_load = ((opp_axle_distance / _vehicle.wheelbase) / 2) * weight
	
	var long_load = (_vehicle.cg_height / _vehicle.wheelbase) * _vehicle.mass * long_accel
	var lat_load = (_vehicle.cg_height / _vehicle.track_width) * _vehicle.mass * lat_accel
	if (front): long_load *= -1
	if (not left): lat_load *= -1
	
	var total_load = stationary_load + long_load + lat_load
	
	return total_load

# Steers the wheel if it is steerable
func _steer(delta):
	var steering_angle = rotation_degrees
	var speed = Utility.p_to_m(_vehicle.linear_velocity.dot(forward))
	var steering_speed = _vehicle.steering_speed
	
	# Low speed steering to avoid instability
	if abs(speed) < LOW_SPEED_THRESHOLD:
		var desired_angle = _steering_input * max_steering_angle
		steering_angle = lerp(rotation_degrees, desired_angle, steering_speed * 0.1)

	# Reverse steering 
	elif speed < 0:
		var desired_angle = _steering_input * max_steering_angle
		var B = 2
		var C = 5
		var speed_sens = 1 * B/ ((linear_velocity.length() - LOW_SPEED_THRESHOLD + 1) * C)
		steering_angle = lerp(rotation_degrees, desired_angle, steering_speed * speed_sens)
	
	# Oversteer/drift steering
	elif _vehicle.oversteering:
		var desired_angle = _steering_input * max_steering_angle
		steering_angle = lerp(rotation_degrees, desired_angle, steering_speed * COUNTER_STEER_SPEED)
	
	# Forward steering
	else:
		var max_slip = tire_model.peak_slip_angle - _vehicle.understeer_prevention
		var desired_slip_angle = (_steering_input * max_slip)
		
		# Determine actual target slip angle based on steering speed
		var target_slip_angle = desired_slip_angle
		if abs(target_slip_angle) > abs(slip_angle):
			target_slip_angle = lerp(slip_angle, target_slip_angle, steering_speed)
		
		# If the current wheel is sliding or rears are not about to slide, get max angle out of this wheel
		var cur_slip
		if abs(slip_angle) >= max_slip or _vehicle.rear_slip_angle < max_slip - _vehicle.oversteer_prevention:
			cur_slip = slip_angle
		# If rears are at the limit and this wheel isn't sliding, get max angle out of the rears (prevent oversteer)
		else:
			cur_slip = _vehicle.rear_slip_angle
		
		if abs(_steering_input) < 0.01:
			steering_angle = lerp(steering_angle, 0.0, steering_speed * CENTERING_SPEED)
		else:
			var error = target_slip_angle - slip_angle
			var diff = (cur_slip - _last_slip_angle) / delta
			var pd = _pd_controller(STEERING_FORCE, STEERING_DERIVATIVE, error, diff)
			steering_angle += pd * delta
			_last_slip_angle = cur_slip
		
	rotation_degrees = clamp(steering_angle, -max_steering_angle, max_steering_angle)

func _pd_controller(p_gain: float, d_gain: float, error: float, diff: float):
	return p_gain * error + d_gain * -diff

# Compute all the lateral forces on the tire
func _lateral_forces(delta):
	var lateral_velocity = linear_velocity.dot(right)
	var longitudinal_velocity = linear_velocity.dot(forward)
	
	if longitudinal_velocity > LOW_SPEED_THRESHOLD:
		slip_angle = rad_to_deg(-atan2(lateral_velocity, longitudinal_velocity))
	else:
		var max_slip_angle = 15.0
		var low_speed_slip = rad_to_deg(-atan2(lateral_velocity, LOW_SPEED_THRESHOLD))
		slip_angle = clamp(low_speed_slip, -max_slip_angle, max_slip_angle)

# Compute all longitudinal forces on the tire
func _longitudinal_forces(delta):
	var v_long = linear_velocity.dot(forward)
	
	if v_long < LOW_SPEED_THRESHOLD:
		var slip_delta = ((angular_velocity * radius) - v_long) - abs(v_long) * _diff_slip_ratio
		slip_delta /= SLIP_RATIO_RELAXATION
		_diff_slip_ratio += slip_delta * delta
		slip_ratio = _diff_slip_ratio
	else:
		slip_ratio = ((angular_velocity * radius) - v_long) / max(abs(v_long), 0.001)
	
	var brake_torque = -2000 * _brake_input * sign(angular_velocity)
	
	_total_torque += _drive_torque + brake_torque

# Public functions
func set_drive_torque(torque: float):
	_drive_torque = torque

func set_steering_input(input: float):
	_steering_input = (input)

func set_brake_input(input: float):
	_brake_input = input

func set_vehicle(vehicle):
	_vehicle = vehicle
