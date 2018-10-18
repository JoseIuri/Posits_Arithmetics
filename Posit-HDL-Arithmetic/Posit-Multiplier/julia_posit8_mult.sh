#!/bin/bash

function posit_mult(y1,y2)
		print(PS(y1),"\t")
		print(PS(y2),"\t")
	       	println(PS(y1)*PS(y2))
end

if ARGS[1] == "--help"
	println("Usgae: julia julia_posit8_mult.sh N<size of operands> es<Exp size>")
else
	using SigmoidNumbers
	N = parse(ARGS[1])
	es = parse(ARGS[2])
	PS=Posit{N,es}
	f1=open("Pin1_8bit.txt")
	f2=open("Pin2_8bit.txt")
	lines1 = readlines(f1)
	lines2 = readlines(f2)
	for l = 1:65536
		x1="0b"lines1[l]
		x2="0b"lines2[l]
		y1=parse(x1)
		y2=parse(x2)
		posit_arith(y1,y2)
	end
end


