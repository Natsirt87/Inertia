extends Node

# Convert between pixels and meters
func p_to_m(pixels):
	return pixels / 50;

func m_to_p(meters):
	return meters * 50;

# Convert between godot force and newtons
func f_to_n(force):
	return force / 50;

func n_to_f(newtons):
	return newtons * 50;

# Convert between newton meters and force pixels
func nm_to_fp(nm):
	return nm * 2500;

func fp_to_nm(fp):
	return fp / 2500;

# Convert pixels/second to miles/hour
func ps_to_mph(ps):
	return ps * 0.04473873;

# Convert meters/second to miles/hour
func ms_to_mph(ms):
	return ms * 2.23694;
