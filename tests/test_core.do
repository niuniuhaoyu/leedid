clear all
set more off
adopath ++ "."
set obs 8
gen id = _n
gen g = id>4
gen y = mod(id-1,4)+1
gen s1 = 1
gen s2 = 1
expand 2
bys id: gen t = _n
replace y = y + 1 + 2*g if t==2
replace s1=0 if id==4 & t==2
replace s2=0 if id==8 & t==2
replace y=. if s1*s2==0
leedid y, unit(id) time(t) treat(g) selection(s1 s2) directions(1 -1) probs(.25 .75) reps(0)
assert abs(e(pi0)-2/3)<1e-12
assert abs(e(pi1)-2/3)<1e-12
assert abs(e(bounds)[1,2]-2)<1e-12
assert abs(e(bounds)[1,3]-2)<1e-12
assert abs(e(bounds)[2,2]-.5)<1e-12
assert abs(e(bounds)[2,3]-3.5)<1e-12
assert abs(e(qtt)[1,2])<1e-12
assert abs(e(qtt)[2,3]-4)<1e-12
count if e(sample)
assert r(N)==16
matrix b0=e(b)
leedid y, unit(id) time(t) treat(g) selection(s1 s2) directions(1 -1) probs(.1(.1).9) reps(0)
assert mreldif(b0,e(b))<1e-12
replace s1=1
replace s2=1
replace y=mod(id-1,4)+1+(1+2*g)*(t==2)
leedid y, unit(id) time(t) treat(g) selection(s1) directions(1) reps(0)
assert e(pi0)==1 & e(pi1)==1
assert abs(e(bounds)[1,2]-2)<1e-12
assert abs(e(bounds)[1,3]-2)<1e-12
assert abs(e(bounds)[2,2]-2)<1e-12
assert abs(e(bounds)[2,3]-2)<1e-12
preserve
expand 2 if id==1 & t==1
capture leedid y, unit(id) time(t) treat(g) selection(s1) directions(1) reps(0)
assert _rc!=0
restore
replace g=1 if id==1 & t==2
capture leedid y, unit(id) time(t) treat(g) selection(s1) directions(1) reps(0)
assert _rc==459
replace g=0 if id==1
replace s1=0 if id==1 & t==1
capture leedid y, unit(id) time(t) treat(g) selection(s1) directions(1) reps(0)
assert _rc==459
replace s1=1
replace y=. if id==1 & t==1
capture leedid y, unit(id) time(t) treat(g) selection(s1) directions(1) reps(0)
assert _rc==459
display "TEST_PASS"
