class_name Drivetrain
extends Node2D

var FLYWHEEL_RADIUS: float = 0.3

@export var engine_torque_curve: Curve
@export var redline_rpm: float = 7000
@export var idle_rpm: float = 1000
@export var gear_ratios: Array
@export var final_drive: float
@export_range(-1, 1) var torque_split: float
@export var flywheel_weight: float = 9

var _rpm: float = 0
var _clutch_in: bool = false
var _gear: int = 1
var _wheels: Array
var _front_wheels: Array
var _rear_wheels: Array
var _throttle_input: float = 0


func _physics_process(delta):
	var front_ang_vel = max(_front_wheels[0].angular_velocity, _front_wheels[1].angular_velocity)
	var rear_ang_vel = max(_rear_wheels[0].angular_velocity, _rear_wheels[1].angular_velocity)
	
	var wheel_angular_velocity
	match torque_split:
		1:
			wheel_angular_velocity = front_ang_vel
		-1:
			wheel_angular_velocity = rear_ang_vel
		_:
			wheel_angular_velocity = max(front_ang_vel, rear_ang_vel)
	
	var gear_ratio = gear_ratios[_gear]
	_rpm = wheel_angular_velocity * gear_ratio * final_drive * 60 / (2 * PI)
	
	if _rpm < idle_rpm:
		_rpm = idle_rpm
	
	var engine_torque = engine_torque_curve.sample((_rpm - idle_rpm) / (redline_rpm - idle_rpm))
	var wheel_torque = engine_torque * final_drive * gear_ratio
	
	var front_torque_split = (1 + torque_split) / 2
	var rear_torque_split = (1 - torque_split) / 2
	
	if _rpm >= redline_rpm:
		_throttle_input = -1
	
	var front_torque = front_torque_split * _throttle_input * wheel_torque
	var rear_torque = rear_torque_split * _throttle_input * wheel_torque
	
	for wheel in _front_wheels:
		wheel.set_drive_torque(front_torque / 2)
	for wheel in _rear_wheels:
		wheel.set_drive_torque(rear_torque / 2)

func set_throttle_input(input: float):
	_throttle_input = input

func set_clutch_in(val: bool):
	_clutch_in = val

func shift_up():
	_gear = min(_gear + 1, len(gear_ratios) - 1)

func shift_down():
	_gear = max(_gear - 1, 0)

func set_wheels(arr: Array):
	_wheels = arr

func set_front_wheels(arr: Array):
	_front_wheels = arr

func set_rear_wheels(arr: Array):
	_rear_wheels = arr
