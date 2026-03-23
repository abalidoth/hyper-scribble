extends HyperPrimitive
class_name HyperSegment

#A hyperbolic line segment between two end points.


var color: Color
	

func _draw():
	var c = MathUtils.geodesic_center(active_coordinates[0], active_coordinates[1])
	var r = c.distance_to(active_coordinates[0])
	var a1 = (active_coordinates[0]-c).angle()
	var a2 = (active_coordinates[1]-c).angle()
	
	if a1<0:
		a1 += TAU
	if a2<0:
		a2+= TAU
	
	
	draw_arc(
		c*screen_radius,
		r*screen_radius,
		a1,
		a2,
		20,
		color,
		#false,
		3.0
	)
