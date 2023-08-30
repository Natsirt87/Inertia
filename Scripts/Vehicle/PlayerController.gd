class_name PlayerController
extends Node2D

@export_enum("RX-7", "Alfa", "Mini") var vehicle_name : String

var vehicle : Vehicle

# Called when the node enters the scene tree for the first time.
func _ready():
	create_vehicle();

func _physics_process(delta):
	if vehicle:
		vehicle.set_throttle_input(Input.get_action_strength("accelerate"))
		vehicle.set_brake_input(Input.get_action_strength("brake"))
		
		var steer_left = Input.get_action_strength("steer_left")
		var steer_right = Input.get_action_strength("steer_right")
		vehicle.set_steering_input(steer_right - steer_left)
		
		if Input.is_action_just_pressed("clutch_in"):
			vehicle.set_clutch_in(true)
		elif Input.is_action_just_released("clutch_in"):
			vehicle.set_clutch_in(false)
		
		if Input.is_action_just_pressed("shift_up"):
			vehicle.shift_up()
		
		if Input.is_action_just_pressed("shift_down"):
			vehicle.shift_down()

# Create the player vehicle wherever this player controller currently is
func create_vehicle():
	vehicle = load("res://Vehicles/Cars/" + vehicle_name + ".tscn").instantiate();
	
	add_child(vehicle);
	
	var camera = VehicleCamera.new();
	camera.set_name("PlayerCamera");
	vehicle.add_child(camera);
	camera.make_current();
