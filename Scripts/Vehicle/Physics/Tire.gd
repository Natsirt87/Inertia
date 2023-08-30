class_name Tire
extends Node2D

var MAGNITUDE_THRESHOLD = 0.01

enum Surface {DRY, WET, DIRT}

@export_file("*.txt") var tire_config
@export var friction: float = 1.0

var peak_slip_ratio: float = 0
var peak_slip_angle: float = 0

var _tire_data: ConfigFile

func _ready():
	_tire_data = ConfigFile.new()
	var err = _tire_data.load(tire_config)

	if err != OK:
		print("Error loading tire data")
		return


func compute_force(slip_ratio, slip_angle, tire_load, surface_type: Surface, forward, right):
	var surface_name = Surface.keys()[surface_type]
	
	peak_slip_ratio = _tire_data.get_value(surface_name + "_LONG", "peak")
	peak_slip_angle = _tire_data.get_value(surface_name + "_LAT", "peak")
	
	var slip_vector = Vector2(slip_angle / peak_slip_angle, slip_ratio / peak_slip_ratio)
	
	var force_long
	var force_lat
	
	if slip_vector.length() < MAGNITUDE_THRESHOLD:
		force_long = _compute_long_force(slip_ratio, tire_load, surface_type)
		force_lat = _compute_lat_force(slip_angle, tire_load, surface_type)
	else:
		var max_long = _compute_long_force(slip_vector.length() * peak_slip_ratio, tire_load, surface_type)
		var max_lat = _compute_lat_force(slip_vector.length() * peak_slip_angle, tire_load, surface_type)
		force_long = slip_vector.y / slip_vector.length() * max_long
		force_lat = slip_vector.x / slip_vector.length() * max_lat
	
	var applied_force = Vector2.ZERO
	applied_force += force_long * forward
	applied_force += force_lat * right
	
	return applied_force
	
func _compute_long_force(slip_ratio, tire_load, surface_type: Surface):
	var section = Surface.keys()[surface_type] + "_LONG"
	var stiffness = _tire_data.get_value(section, "stiffness")
	var shape = _tire_data.get_value(section, "shape")
	var curve = _tire_data.get_value(section, "curve")
	
	return _magic_formula(slip_ratio, stiffness, shape, curve) * tire_load * friction

func _compute_lat_force(slip_angle, tire_load, surface_type: Surface):
	var section = Surface.keys()[surface_type] + "_LAT"
	var stiffness = _tire_data.get_value(section, "stiffness")
	var shape = _tire_data.get_value(section, "shape")
	var curve = _tire_data.get_value(section, "curve")
	
	return _magic_formula(slip_angle, stiffness, shape, curve) * tire_load * friction

func _magic_formula(input, stiffness, shape, curve):
	var B = stiffness
	var C = shape
	var E = curve
	var x = input
	
	return sin(C * atan(B * x - E * (B * x - atan(B * x))))
