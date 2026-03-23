extends Node

func cpx_conj(z: Vector2) -> Vector2:
	return Vector2(z.x,-z.y)

func cpx_times(w:Vector2, z:Vector2) -> Vector2:
	return Vector2(w.x*z.x-w.y*z.y, w.x*z.y+w.y*z.x)

func cpx_norm_sqr(z:Vector2) -> float:
	return cpx_times(z, cpx_conj(z)).x

func cpx_invert(z:Vector2)-> Vector2 :
	return cpx_conj(z)/cpx_norm_sqr(z)

func cpx_divide(w:Vector2, z:Vector2)-> Vector2:
	return cpx_times(w, cpx_invert(z))

func center_translation(beta: Vector2, z: Vector2)->Vector2:
	return cpx_divide(beta + z,cpx_times(cpx_conj(beta),z)+Vector2(1,0))
	
func inv_center_translation(beta: Vector2, z:Vector2) -> Vector2:
	var norm = 1/(cpx_norm_sqr(beta)-1)
	return norm*cpx_divide(beta-z,cpx_times(cpx_conj(beta),z)-Vector2(1,0))
	
func geodesic_translation(start:Vector2, end:Vector2, z:Vector2) -> Vector2:
	var beta : Vector2 = inv_center_translation(start,end)
	var work = z
	work = inv_center_translation(start, work)
	work = center_translation(beta, work)
	work = center_translation(start, work)
	return work
	
func geodesic_center(u: Vector2, v: Vector2) -> Vector2:
	print(u,v)
	var mu = (u + cpx_invert(cpx_conj(u)))/2
	var mv = (v + cpx_invert(cpx_conj(v)))/2
	print(mu,mv)
	var du = u - cpx_invert(cpx_conj(u))
	var dv = v - cpx_invert(cpx_conj(v))
	
	print("du dv ",du,dv)
	#slopes of the perpendicular bisectors
	var su = -du.x/du.y
	var sv = -dv.x/dv.y
	
	print("su sv ",su,sv)
	
	#solve the linear system of equations
	var center_x = (-sv*mv.x + mv.y + su*mu.x - mu.y) / (su - sv)
	var center_y = su*center_x - su*mu.x + mu.y
	print(center_x , center_y)
	return Vector2(center_x, center_y)


func disk_to_screen(z: Vector2, screen_center: Vector2, radius: float):
	return z*radius + screen_center
