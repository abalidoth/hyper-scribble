extends Node2D
class_name HyperPrimitive

var screen_radius: float
var screen_center: Vector2
var active_coordinates: Array[Vector2]
var saved_coordinates: Array[Vector2]
var panning = false
var pan_center: Vector2

#Abstract Class that defines all drawing primitives in the hyperbolic plane
	
	
func _on_begin_pan(begin_loc:Vector2):
	panning = true
	saved_coordinates = active_coordinates.duplicate(true)
	pan_center = begin_loc
	
	
func _on_pan_move(move_loc:Vector2):
	for i in range(len(saved_coordinates)):
		active_coordinates[i]=MathUtils.geodesic_translation(pan_center, move_loc, saved_coordinates[i])
	queue_redraw()

func _on_end_pan(end_loc:Vector2):
	panning=false
	for i in range(len(saved_coordinates)):
		active_coordinates[i]=MathUtils.geodesic_translation(pan_center, end_loc, saved_coordinates[i])
	queue_redraw()
	
func _on_pan_out_of_bounds():
	for i in range(len(saved_coordinates)):
		active_coordinates[i]=saved_coordinates[i]
	queue_redraw()
	
func _on_cancel_pan():
	for i in range(len(saved_coordinates)):
		active_coordinates[i]=saved_coordinates[i]
	queue_redraw()
