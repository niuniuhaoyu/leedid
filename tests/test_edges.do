clear all
set more off
adopath ++ "."
import delimited "tests/generated/reference_data.csv", clear asdouble
leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) reps(0)
matrix base=e(b)
scalar p=e(pi0)
assert abs(e(pi0)-82/101)<1e-12
assert e(N_units)==300
assert e(N_control)==101 & e(N_treated)==101
* Unit/row order and string identifier must not change estimates.
gen str12 sid="unit"+string(id)
gsort -id -period
leedid y, unit(sid) time(period) treat(g) selection(s1 s2) directions(1 -1) reps(0)
assert mreldif(base,e(b))<1e-12
* Outcomes outside selection are irrelevant; the full roster remains counted.
replace y=99999 if s1*s2==0
leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) reps(0)
assert mreldif(base,e(b))<1e-12
* Swapping treatment and directions reverses DiD bounds.
replace g=1-g
leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(-1 1) reps(0)
assert abs(e(b)[1,1]+base[1,2])<1e-12
assert abs(e(b)[1,2]+base[1,1])<1e-12
replace g=1-g
preserve
replace s2=0 if s1==0
capture leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) reps(0)
assert _rc==459
restore
preserve
drop if id==1 & period==2
capture leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) reps(0)
assert _rc==459
restore
preserve
replace s1=. if id==1 & period==1
capture leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) reps(0)
assert _rc==459
restore
* Fractional retained mass, with ties, checked directly against hand arithmetic.
mata:
x=(0\1\1\8)
y=x
assert(abs(_ld_trim(x,.625,0)-.6)<1e-12)
assert(abs(_ld_trim(x,.625,1)-3.8)<1e-12)
assert(all(x:==y))
assert(_ld_q((1\2\3),1/3)==1)
assert(_ld_q((1\2\3),0)==1)
assert(_ld_q((1\2\3),1)==3)
assert(abs(_ld_critical(0,.5,.95)-invnormal(.975))<1e-12)
assert(abs(_ld_critical(10,.1,.95)-invnormal(.95))<1e-12)
end
* Duplicate sources are an input error, not an extra selection mechanism.
capture leedid y, unit(id) time(period) treat(g) selection(s1 s1) directions(1 1) reps(0)
assert _rc!=0
* Explicit period selection ignores incomplete rows outside the chosen window.
preserve
local next=_N+1
set obs `next'
replace period=3 in `next'
leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) pre(1) post(2) reps(0)
assert mreldif(base,e(b))<1e-12
restore
* A single resampling cluster cannot support bootstrap inference.
gen byte onecluster=1
capture leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) cluster(onecluster) reps(9)
assert _rc==459
display "TEST_PASS"
