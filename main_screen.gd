extends Node2D
@export var radius = 100

var panning = false
var drawing = false

signal begin_pan(pan_center:Vector2)
signal pan_move(move_loc: Vector2)
signal pan_out_of_bounds()
signal end_pan(move_loc:Vector2)
signal cancel_pan()
signal draw_event(tool: String, event:String, loc: Vector2)

var current_tool: String = "segment"


func on_disk(z: Vector2) -> bool:
	return z.distance_to(%CircleCenter.position)<radius

func _ready() -> void:
	#create the test segment
	%GeometryManager.screen_radius = radius
	
	queue_redraw()
	
func _draw() -> void:
	draw_circle($CircleCenter.position,radius,Color.WHITE, false)
		
func _input(event: InputEvent) -> void:
	var valid:bool = false
	if "position" in event:
		valid = on_disk(event.position)
	if event is InputEventMouseButton:
		#Draw button
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if current_tool in ["segment","ray","line"]:
				if event.pressed and valid:
					drawing = true
					draw_event.emit(current_tool, "start", event.position)
				elif not event.pressed and valid and drawing:
					drawing = false
					draw_event.emit(current_tool, "end", event.position)
				elif not event.pressed and drawing and not valid:
					drawing = false
					draw_event.emit(current_tool, "cancel", event.position)
		
		
		#Pan button
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			#functions of the pan (right) button
			if not panning and event.pressed and valid:
				#"correct" begin pan
				panning = true
				begin_pan.emit(event.position)
			elif not event.pressed and valid and panning:
				#correct end pan
				panning = false
				end_pan.emit(event.position)
			elif not event.pressed and panning and not valid:
				#released out of bounds, cancel pan
				panning = false
				cancel_pan.emit(event.position)
		else:
			pass
				
						
	if event is InputEventMouseMotion:
		if panning:
			if valid:
				#correct move
				pan_move.emit(event.position)
			else:
				#pan out of bounds, send reset
				pan_out_of_bounds.emit()
		if drawing:
			if current_tool in ["segment","ray","line"]:
				if valid:
					draw_event.emit(current_tool, "move", event.position)
				else:
					print("emit out of bounds")
					draw_event.emit(current_tool, "out_of_bounds", event.position)
				


func _on_tool_bar_tool_selected(tool: String) -> void:
	current_tool = tool
