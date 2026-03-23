extends Node2D
@export var radius = 100
var Segment = preload("res://hyper_segment.tscn")
var test_seg
var primitives = []

var panning = false

signal begin_pan(pan_center:Vector2)
signal pan_move(move_loc: Vector2)
signal pan_out_of_bounds()
signal end_pan(move_loc:Vector2)
signal cancel_pan()


func on_disk(z: Vector2) -> bool:
	return z.distance_to(%CircleCenter.position)<radius

func _ready() -> void:
	var test_seg = Segment.instantiate()
	primitives.append(test_seg)
	$Primitives.add_child(test_seg)
	test_seg.active_coordinates = [
		Vector2(0.25, 0.35),
		Vector2(0.15, -0.45)
	]
	test_seg.color = Color.BLACK
	test_seg.screen_radius = radius
	test_seg.screen_center = $Primitives.position
	
	begin_pan.connect(test_seg._on_begin_pan)
	end_pan.connect(test_seg._on_end_pan)
	cancel_pan.connect(test_seg._on_cancel_pan)
	pan_out_of_bounds.connect(test_seg._on_pan_out_of_bounds)
	pan_move.connect(test_seg._on_pan_move)
	
	
	queue_redraw()
	
func _draw() -> void:
	draw_circle($CircleCenter.position,radius,Color.WHITE, false)
	for primitive in primitives:
		print("drawing", primitive)
		primitive.draw()
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			#functions of the pan (right) button
			if not panning and event.pressed and on_disk(event.position):
				#"correct" begin pan
				panning = true
				begin_pan.emit(event.position)
			elif not event.pressed and on_disk(event.position) and panning:
				#correct end pan
				panning = false
				end_pan.emit(event.position)
			elif not event.pressed and panning and not on_disk(event.position):
				#released out of bounds, cancel pan
				panning = false
				cancel_pan.emit(event.position)
				
				
						
	if event is InputEventMouseMotion:
		if panning:
			if on_disk(event.position):
				#correct move
				pan_move.emit(event.position)
			else:
				#pan out of bounds, send reset
				pan_out_of_bounds.emit()
