extends Node2D
class_name GeometryManager

var true_pool_n_r: Array[float] = []
var true_pool_n_i: Array[float] = []
var true_pool_d_r: Array[float] = []
var true_pool_d_i: Array[float] = []

var cache_pool_r: Array[float] = []
var cache_pool_i: Array[float] = []

var screen_radius : float

var panning:bool = false
var pan_center: MathUtils.complex = MathUtils.complex.zero()

var line_start: MathUtils.complex
var line_exists: bool = false

var current_tool: String = "segment"

var view_shifts: Array[MathUtils.mobius]

var static_view: MathUtils.mobius = MathUtils.mobius.id()
var pan_view: MathUtils.mobius = MathUtils.mobius.id()
var current_view: MathUtils.mobius = MathUtils.mobius.id()



func screen_vec_to_complex(pos: Vector2) -> MathUtils.complex:
	var p: Vector2 = (pos - position)/screen_radius
	return MathUtils.complex.new(p.x,p.y)
	
func complex_to_screen_vec(z: MathUtils.complex) -> Vector2:
	return z.to_vec2()*screen_radius + position

func get_cache_complex(indices : Array[int]) -> Array[MathUtils.complex]:
	var out : Array[MathUtils.complex] = []
	for i in indices:
		out.append(MathUtils.complex.new(
				cache_pool_r[i],
				cache_pool_i[i]
			))
	return out

func update_cache() -> void:
	cache_pool_r = []
	cache_pool_i = []
	for idx in range(len(true_pool_n_r)):
		var n_r = true_pool_n_r[idx]
		var n_i = true_pool_n_i[idx]
		var d_r = true_pool_d_r[idx]
		var d_i = true_pool_d_i[idx]
		var n = MathUtils.complex.new(n_r, n_i)
		var d = MathUtils.complex.new(d_r, d_i)
		var h = MathUtils.hom_complex.new(n,d)
		var new_h = current_view.apply_to_hom(h)
		var new_z = new_h.eval()
		cache_pool_r.append(new_z.real)
		cache_pool_i.append(new_z.imag)
		
func clear_last_primitive():
	var p = primitives.pop_back()
	for i in range(len(p.point_idx)):
		for a in [
			true_pool_n_r,
			true_pool_n_i,
			true_pool_d_r,
			true_pool_d_i,
			cache_pool_r,
			cache_pool_i
		]:
			a.pop_back()

var primitives: Array[Primitive]

class Drawing:
	pass
	
class ArcDrawing extends Drawing:
	var center: Vector2
	var radius: float
	var start_angle : float
	var end_angle : float
	const points : int = 20
	var color : Color
	var thickness : float
	
	func _init(
		center_: Vector2,
		radius_: float,
		start_angle_ : float,
		end_angle_: float,
		color_: Color,
		thickness_ : float
	) -> void:
		center = center_
		radius = radius_
		start_angle = start_angle_
		end_angle = end_angle_
		color = color_
		thickness = thickness_
	
class PolylineDrawing extends Drawing:
	
	var points: Array[Vector2]
	var thickness: float
	var color: Color
	
	func _init(points_, thickness_, color_):
		points = points_
		thickness = thickness_
		color = color_

class Primitive:
	var point_idx: Array[int]
	var manager: GeometryManager
	func get_points() -> Array[MathUtils.complex]:
		return manager.get_cache_complex(point_idx)
	
	func draw() -> Array[Drawing]:
		return []
		
class SegPrimitive extends Primitive:
	var color : Color
	var thickness : float
	
	func _init(
		start_point: int,
		end_point: int,
		color_: Color,
		thickness_: float,
		manager_: GeometryManager
		
	) -> void:
		point_idx= [start_point, end_point]
		color = color_
		thickness = thickness_
		manager = manager_
		
	func draw()-> Array[Drawing]:
		var ends = get_points()
		var c = MathUtils.geodesic_center(ends[0], ends[1])
		var r = sqrt(c.sub(ends[0]).norm_sqr())
		var a1 = fposmod((ends[0].sub(c)).arg(), TAU)
		var a2 = fposmod((ends[1].sub(c)).arg(), TAU)
		
		if abs(a1-a2)>PI:
			if a1<a2:
				a1+=TAU
			else:
				a2+=TAU

		return [ArcDrawing.new(
			c.to_vec2()*manager.screen_radius,
			r*manager.screen_radius,
			a1,
			a2,
			color,
			thickness
		)]
	
class RayPrimitive extends Primitive:
	var color : Color
	var thickness : float
	
	func _init(
		start_point: int,
		end_point: int,
		color_: Color,
		thickness_: float,
		manager_: GeometryManager
		
	) -> void:
		point_idx= [start_point, end_point]
		color = color_
		manager = manager_
		thickness = thickness_
		
	func draw()-> Array[Drawing]:
		var ends = get_points()
		var c = MathUtils.geodesic_center(ends[0], ends[1])
		var r = sqrt(c.sub(ends[0]).norm_sqr())
		var half_angle = asin(1/sqrt(c.norm_sqr()))
		var radius_angle = c.neg().arg()
		var end1 = fposmod(radius_angle - half_angle, TAU)
		var end2 = fposmod(radius_angle + half_angle, TAU)
		var p1 = fposmod((ends[0].sub(c)).arg(), TAU)
		var p2 = fposmod((ends[1].sub(c)).arg(), TAU)
		var a1: float = p1
		var a2: float
		
		if sign(MathUtils.to_pi_range(end1-p1))==sign(MathUtils.to_pi_range(p2-p1)):
			a2=end1
		else:
			a2=end2
			
		
		
		if abs(a1-a2)>PI:
			if a1<a2:
				a1+=TAU
			else:
				a2+=TAU

		return [ArcDrawing.new(
			c.to_vec2()*manager.screen_radius,
			r*manager.screen_radius,
			a1,
			a2,
			color,
			thickness
		)]

class LinePrimitive extends Primitive:
	var color : Color
	var thickness: float
	
	func _init(
		start_point: int,
		end_point: int,
		color_: Color,
		thickness_ : float,
		manager_: GeometryManager
		
	) -> void:
		point_idx= [start_point, end_point]
		color = color_
		thickness = thickness_
		manager = manager_
		
	func draw()-> Array[Drawing]:
		var ends = get_points()
		var c = MathUtils.geodesic_center(ends[0], ends[1])
		var r = sqrt(c.sub(ends[0]).norm_sqr())
		var half_angle = asin(1/sqrt(c.norm_sqr()))
		var radius_angle = c.neg().arg()
		var a1 = fposmod(radius_angle - half_angle, TAU)
		var a2 = fposmod(radius_angle + half_angle, TAU)
		
		if abs(a1-a2)>PI:
			if a1<a2:
				a1+=TAU
			else:
				a2+=TAU

		return [ArcDrawing.new(
			c.to_vec2()*manager.screen_radius,
			r*manager.screen_radius,
			a1,
			a2,
			color,
			thickness
		)]

class FreehandPrimitive extends Primitive:
	var thickness : float
	var color: Color
	
	func _init(color_ : Color, thickness_: float, manager_: GeometryManager) -> void:
		color = color_
		thickness = thickness_
		manager = manager_
	
	func add_point(idx: int) -> void:
		point_idx.append(idx)
	
	func draw() -> Array[Drawing]:
		var complex_points = get_points()
		var vec_points: Array[Vector2] = []
		for z in complex_points:
			vec_points.append(z.to_vec2() * manager.screen_radius)
			
		return [PolylineDrawing.new(
			vec_points,
			thickness,
			color
		)]

func add_hom_to_true(z:MathUtils.hom_complex) -> int:
	true_pool_n_r.append(z.num.real)
	true_pool_n_i.append(z.num.imag)
	true_pool_d_r.append(z.den.real)
	true_pool_d_i.append(z.den.imag)
	return len(true_pool_n_r)-1

func complex_to_true(z: MathUtils.complex) -> MathUtils.hom_complex:
	var z_hom : MathUtils.hom_complex = MathUtils.hom_complex.from_complex(z)
	return current_view.invert().apply_to_hom(z_hom)

func create_geodetic(
	start_point: MathUtils.complex,
	end_point: MathUtils.complex,
	color: Color,
	thickness: float,
	type: String
) -> void:
	var start_true: MathUtils.hom_complex = complex_to_true(start_point)
	var end_true: MathUtils.hom_complex = complex_to_true(end_point)
	
	var start_idx = add_hom_to_true(start_true)
	var end_idx = add_hom_to_true(end_true)
	update_cache()
	var s: Primitive
	if type == "segment":
		s = SegPrimitive.new(
			start_idx,
			end_idx,
			color,
			thickness,
			self
		)
	elif type == "ray":
		s = RayPrimitive.new(
			start_idx,
			end_idx,
			color,
			thickness,
			self
		)
	elif type == "line":
		s = LinePrimitive.new(
			start_idx,
			end_idx,
			color,
			thickness,
			self
		)
	primitives.append(s)
	queue_redraw()

func create_freehand(
	start_point: MathUtils.complex,
	color: Color,
	thickness: float,
) -> void:
	var s: FreehandPrimitive
	s = FreehandPrimitive.new(color, thickness, self)
	
	var start_hom : MathUtils.hom_complex = complex_to_true(start_point)
	var start_idx : int = add_hom_to_true(start_hom)
	
	update_cache()

	s.add_point(start_idx)
	primitives.append(s)
	
func update_freehand(new_point: MathUtils.complex) -> void:
	var s = primitives[-1]
	assert(s is FreehandPrimitive, "Calling update_freehand when most recent primitive is not freehand")
	var new_true = complex_to_true(new_point)
	var new_idx = add_hom_to_true(new_true)
	
	update_cache()
	
	s.add_point(new_idx)
	

func _draw() -> void:
	for p: Primitive in primitives:
		var d_list: Array[Drawing] = p.draw()
		for d: Drawing in d_list:
			if d is ArcDrawing:
				draw_arc(
					d.center,
					d.radius,
					d.start_angle,
					d.end_angle,
					d.points,
					d.color,
					d.thickness
				)
			elif d is PolylineDrawing:
				draw_polyline(
					d.points,
					d.color,
					d.thickness
				)


func _on_main_screen_begin_pan(pan_center_screen: Vector2) -> void:
	panning = true
	pan_center = screen_vec_to_complex(pan_center_screen)
	static_view = current_view
	


func _on_main_screen_cancel_pan() -> void:
	panning = false


func _on_main_screen_end_pan(move_loc: Vector2) -> void:
	var pan_end = screen_vec_to_complex(move_loc)
	pan_view = MathUtils.geodesic_translation(pan_center, pan_end)
	view_shifts.push_front(pan_view)
	var work = MathUtils.mobius.id()
	for shift in view_shifts:
		work=work.compose(shift)
	current_view = work
	print("current")
	print(current_view)
	update_cache()
	queue_redraw()


func _on_main_screen_pan_move(move_loc: Vector2) -> void:
	var pan_end = screen_vec_to_complex(move_loc)
	pan_view = MathUtils.geodesic_translation(pan_center, pan_end)
	current_view = pan_view.compose(static_view)
	update_cache()
	queue_redraw()


func _on_main_screen_pan_out_of_bounds() -> void:
	pan_view = MathUtils.mobius.id()
	current_view = static_view
	update_cache()
	queue_redraw()

func random_point() -> MathUtils.complex:
	var theta = randf()* TAU
	var r = sqrt(randf())
	return MathUtils.complex.new(r*cos(theta), r*sin(theta))

func _ready() -> void:
	pass
	#for i in range(500):
		#create_geodetic(
			#random_point(),
			#random_point(),
			#Color(sqrt(randf()),sqrt(randf()),sqrt(randf())),
			#randi_range(1,5),
			#"line"
		#)


func _on_main_screen_draw_event(tool: String, event: String, screen_loc: Vector2) -> void:
	var complex_loc: MathUtils.complex = screen_vec_to_complex(screen_loc)
	var color: Color= %ColorPicker.color
	var thickness: float =  %ThicknessSlider.value
	if tool in ["segment", "ray", "line"]:
		if event == "start":
			line_start = complex_loc
		elif event == "move":
			if line_exists:
				clear_last_primitive()
			create_geodetic(line_start, complex_loc, color , thickness, tool)
			line_exists = true
		elif event == "cancel":
			if line_exists:
				clear_last_primitive()
			line_exists = false
		elif event == "end":
			line_exists = false
		elif event == "out_of_bounds":
			if line_exists:
				clear_last_primitive()
			line_exists = false
	elif tool == "freehand":
		if event == "start":
			create_freehand(complex_loc,color, thickness)
		elif event == "new_point":
			update_freehand(complex_loc)
			
		
	queue_redraw()

func _on_dialog_clear() -> void:
	primitives = []
	for a in [
		true_pool_n_r,
		true_pool_n_i,
		true_pool_d_r,
		true_pool_d_i,
		cache_pool_r,
		cache_pool_i
	]:
		a = []
	
	current_view = MathUtils.mobius.id()
	queue_redraw()
