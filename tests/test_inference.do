clear all
set more off
adopath ++ "."
set seed 775
set obs 120
gen id=_n
gen g=id>60
gen cluster=ceil(id/6)
gen y=rnormal()
gen s=1
expand 2
bys id: gen t=_n
replace y=y+1+g+rnormal()*.3 if t==2
leedid y, unit(id) time(t) treat(g) selection(s) directions(1) reps(39) seed(912)
assert e(reps_success)==39
assert e(reps_failed)==0
assert !missing(e(V)[1,1])
assert e(bounds)[1,2]==e(bounds)[1,3]
assert abs(e(bounds)[1,6]-(e(bounds)[1,2]-invnormal(.975)*e(bounds)[1,4]))<1e-9
matrix b1=e(boot)
leedid y, unit(id) time(t) treat(g) selection(s) directions(1) reps(39) seed(912)
assert mreldif(b1,e(boot))<1e-12
leedid y, unit(id) time(t) treat(g) selection(s) directions(1) reps(39) seed(912) cluster(cluster) graph
assert e(N_clusters)==20
assert e(reps_success)==39
assert mreldif(b1,e(boot))>1e-8
graph export "tests/generated/qtt.png", replace
* Two treatment-pure clusters: some draws contain only one arm.
gen badcluster=g
leedid y, unit(id) time(t) treat(g) selection(s) directions(1) reps(39) seed(912) cluster(badcluster)
assert e(reps_failed)>0
assert missing(e(bounds)[1,4])
assert missing(e(bounds)[1,6])
matrix V=e(V)
assert missing(V[1,1])
display "TEST_PASS"
