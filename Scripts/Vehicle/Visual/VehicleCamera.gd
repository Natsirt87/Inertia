class_name VehicleCamera
extends Camera2D

var zoom_sensitivity : float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	zoom.x += Input.get_action_strength("zoom_in") * zoom_sensitivity * delta
	zoom.y += Input.get_action_strength("zoom_in") * zoom_sensitivity * delta
	zoom.x -= Input.get_action_strength("zoom_out") * zoom_sensitivity * delta
	zoom.y -= Input.get_action_strength("zoom_out") * zoom_sensitivity * delta
