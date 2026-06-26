class_name Utils

static func exp_to_dec(exponent: int):
	var log2 := log(2.0)				# natural log
	var log10_2 := log2 / log(10.0) 	# log10(2)
	var x := float(exponent) * log10_2  # log10(2^k)
	return x
	#var f := x - floor(x)				# fractional part
	#var lead := pow(10.0, f)			# in [1, 10)
	#return int(floor(lead * 1000.0))
