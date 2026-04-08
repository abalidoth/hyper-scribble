extends Node

func to_pi_range(theta:float) -> float:
	var p: float = fposmod(theta,TAU)
	if p < PI:
		return p
	else:
		return p-TAU

class complex:
	var real: float
	var imag: float
	
	func _init(a:float, b:float):
		real = a
		imag = b
	
	
	static func one() -> complex:
		return complex.new(1,0)
	
	static func zero() -> complex:
		return complex.new(0,0)
		
	func _to_string() -> String:
		if imag >= 0:
			return "%.3f + %.3fi"%[real, imag]
		else:
			return "%.3f - %.3fi"%[real, -imag]
			
	func conj() -> complex:
		return complex.new(real, -imag)
		
	func neg() -> complex:
		return complex.new(-real, -imag)
		
	func add(z: complex) -> complex:
		return complex.new(real + z.real, imag + z.imag)
		
	func sub(z: complex) -> complex:
		return add(z.neg())
	
	func mul(z: complex) -> complex:
		return complex.new(real*z.real - imag*z.imag, real*z.imag + imag*z.real)
	
	func norm_sqr() -> float:
		return real*real + imag*imag
		
	func scale(l: float) -> complex:
		return complex.new(real*l, imag*l)
		
	func div(z:complex) -> complex:
		var n = 1/z.norm_sqr()
		return mul(z.conj().scale(n))
	
	func arg() -> float:
		return atan2(imag, real)
		
	func to_vec2() -> Vector2:
		return Vector2(real, imag)

class hom_complex:
	
	var num: complex
	var den: complex
	
	func _init(num_: complex, den_:complex):
		num = num_
		den = den_
	

		
	static func from_complex(z:complex) -> hom_complex:
		return hom_complex.new(z,complex.one())
	
	func eval() -> complex:
		return num.div(den)
	
	func rescale(l: complex) -> hom_complex:
		return hom_complex.new(num.mul(l), den.mul(l))

class mobius:
	
	var a: complex
	var b: complex
	var c: complex
	var d: complex
	
	func _init(a_:complex, b_:complex, c_:complex, d_:complex):
		a=a_
		b=b_
		c=c_
		d=d_
		
		
	static func id() -> mobius:
		return mobius.new(
			complex.one(),
			complex.zero(),
			complex.zero(),
			complex.one()
		)
		
	func _to_string() -> String:
		return "(%s)z + (%s)\n--------\n(%s)z + (%s)"%[a,b,c,d]
	func scale(l: complex) -> mobius:
		return mobius.new(a.mul(l), b.mul(l), c.mul(l), d.mul(l))
		
	func apply_to_hom(z:hom_complex) -> hom_complex:
		return hom_complex.new(
			a.mul(z.num).add(b.mul(z.den)),
			c.mul(z.num).add(d.mul(z.den))
		)	
	
	func apply_to_complex(z:complex) -> complex:
		return a.mul(z).add(b).div(c.mul(z).add(d))
	
	func invert() -> mobius:
		return mobius.new(d, b.neg(), c.neg(), a)
		
	func compose(m: mobius) -> mobius:
		return mobius.new(
			a.mul(m.a).add(b.mul(m.c)),
			a.mul(m.b).add(b.mul(m.d)),
			c.mul(m.a).add(d.mul(m.c)),
			c.mul(m.b).add(d.mul(m.d)),
		)
	
func center_translation(z:complex) -> mobius:
	return mobius.new(complex.one(), z, z.conj(), complex.one())

func geodesic_translation(start:complex, end:complex) -> mobius:
	var beta: complex = center_translation(start.neg()).apply_to_complex(end)
	var work : mobius = center_translation(start)
	work = work.compose(center_translation(beta))
	work = work.compose(center_translation(start.neg()))
	return work
#

func geodesic_center(u: complex, v:complex) -> complex:
	var mu = u.add(complex.one().div(u).conj()).scale(0.5)
	var mv = v.add(complex.one().div(v).conj()).scale(0.5)
	
	var du = u.sub(complex.one().div(u).conj())
	var dv = v.sub(complex.one().div(v).conj())
	
	var su = -du.real/du.imag
	var sv = -dv.real/dv.imag
	#find intersection of perp bisectors
	var center_x = (-sv*mv.real + mv.imag + su*mu.real - mu.imag) / (su - sv)
	var center_y = su*center_x - su*mu.real + mu.imag
	
	return complex.new(center_x, center_y)
	
#func disk_to_screen(z: Vector2, screen_center: Vector2, radius: float):
	#return z*radius + screen_center
