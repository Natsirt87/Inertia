class_name Vehicle
extends RigidBody2D

# Constants
var MAX_SPEED = 100

# Exports
@export var steering_speed: float = 0.5
@export var engine_torque: float

@export var cg_height: float
@export var understeer_prevention: float = 0.3
@export var oversteer_prevention: float = 0.2

# Public variables
var linear_accel: Vector2
var angular_accel: float
var oversteering: bool
var rear_slip_angle: float
var rear_peak_slip: float
var rear_axle_dist: float
var front_axle_dist: float
var wheelbase: float
var track_width: float

# Private variables
var _last_velocity: Vector2
var _last_angular_velocity: float
var _front_wheels: Array
var _rear_wheels: Array

# On ready variables
@onready var forward: Vector2 = -global_transform.y.normalized()
@onready var right: Vector2 = global_transform.x.normalized()
@onready var _wheels: Array = $Body/Drivetrain/Wheels.get_children()
@onready var _drivetrain: Drivetrain = $Body/Drivetrain

# Called when the node enters the scene tree for the first time.
func _ready():
	$Body/VehicleSprite.vehicle = self
	
	for wheel in _wheels:
		wheel.set_vehicle(self)
		if wheel.front:
			_front_wheels.append(wheel)
		else:
			_rear_wheels.append(wheel)
	
	_drivetrain.set_wheels(_wheels)
	_drivetrain.set_front_wheels(_front_wheels)
	_drivetrain.set_rear_wheels(_rear_wheels)
	
	var front_left = _front_wheels[0]
	var front_right = _front_wheels[1]
	var rear_left = _rear_wheels[0]
	
	var front_pos = front_left.position * $Body.scale.x
	front_axle_dist = Utility.p_to_m(abs(front_pos.y - center_of_mass.y))
	
	var rear_pos = rear_left.position * $Body.scale.x
	rear_axle_dist = Utility.p_to_m(abs(rear_pos.y - center_of_mass.y))
	
	wheelbase = front_axle_dist + rear_axle_dist
	
	var front_right_pos = front_right.position * $Body.scale.x
	var left_width = Utility.p_to_m(abs(front_pos.x - center_of_mass.x))
	var right_width = Utility.p_to_m(abs(front_right_pos.x - center_of_mass.x))
	track_width = left_width + right_width
	
	print("Center of mass: " + str(center_of_mass))
	print("Front axle distance: " + str(front_axle_dist))
	print("Rear axle distance: " + str(rear_axle_dist))
	print("Wheelbase: " + str(wheelbase))
	print("Track width: " + str(track_width))

func _physics_process(delta):
	# Update unit vectors
	forward = -global_transform.y.normalized()
	right = global_transform.x.normalized()
	
	# Calculate linear_accel in m/s^2
	linear_accel = Utility.p_to_m( (linear_velocity - _last_velocity) / delta )
	#print("Accel: " + str(linear_accel) + "Speed (mph): " + str(Utility.ps_to_mph(linear_velocity.length())))
	
	angular_accel = (angular_velocity - _last_angular_velocity) / delta
	
	_last_velocity = linear_velocity
	_last_angular_velocity = angular_velocity
	_determine_oversteer()

func _determine_oversteer():
	var steer_dir = sign(_front_wheels[0].rotation_degrees)
	# Get outside rear tire
	var rear: Wheel = _rear_wheels[0] if steer_dir > 0 else _rear_wheels[0]
	
	# If the rear outside tire's slip angle is exceeding the max, the car is oversteering
	oversteering = true if abs(rear.slip_angle) > (rear.tire_model.peak_slip_angle) else false
	rear_slip_angle = rear.slip_angle
	rear_peak_slip = rear.tire_model.peak_slip_angle

func set_throttle_input(input: float):
	_drivetrain.set_throttle_input(input)

func set_steering_input(input: float):
	for wheel in _wheels:
		wheel.set_steering_input(input)

func set_brake_input(input: float):
	for wheel in _wheels:
		wheel.set_brake_input(input)

func set_clutch_in(clutch_in: bool):
	_drivetrain.set_clutch_in(clutch_in)

func shift_up():
	_drivetrain.shift_up()

func shift_down():
	_drivetrain.shift_down()

func apply_central_wheel_force(force: Vector2):
	apply_central_force(Vector2(Utility.n_to_f(force.x), Utility.n_to_f(force.y)))

func apply_wheel_force(force: Vector2, offset: Vector2):
	apply_force(Vector2(Utility.n_to_f(force.x), Utility.n_to_f(force.y)), offset)

func apply_wheel_torque(torque: float):
	apply_torque(Utility.nm_to_fp(torque))
