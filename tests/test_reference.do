clear all
set more off
adopath ++ "."
import delimited "tests/generated/reference_data.csv", clear asdouble
leedid y, unit(id) time(period) treat(g) selection(s1 s2) directions(1 -1) probs(.13 .37 .61 .89) reps(0)
matrix original=(e(pi0),e(pi1),e(b),e(qtt)[1...,2]',e(qtt)[1...,3]')
sort id period
mata:
L=st_data(.,tokens("g y s1 s2")); n=rows(L)/2
X=(L[(1::n):*2:-1,1],L[(1::n):*2:-1,2],L[(1::n):*2,2],L[(1::n):*2:-1,3..4],L[(1::n):*2,3..4])
end
import delimited "tests/generated/shared_indices.csv", clear asdouble
mata:
ix=st_data(.,.)
actual=st_matrix("original")
for(j=1;j<=cols(ix);j++) {
 f=_ld_fit(X[ix[,j],],(1,-1),(.13,.37,.61,.89))
 actual=actual\f[(1,2,8..cols(f))]
}
V=variance(actual[2..rows(actual),]); se=sqrt(diagonal(V))'
CI=J(2,2,.)
for(j=1;j<=2;j++) {
 k=1+2*j
 z=_ld_critical(actual[1,k+1]-actual[1,k],max(se[k..(k+1)]),.95)
 CI[j,]=(actual[1,k]-z*se[k],actual[1,k+1]+z*se[k+1])
}
end
import delimited "tests/generated/expected.csv", clear asdouble
mata:
expected=st_data(.,.)
maxerr=max(abs(expected-actual))
st_numscalar("reference_error",maxerr)
printf("Stabilized author-function comparison max absolute error: %g\n",maxerr)
colmax(abs(expected-actual))
expected[1,]
actual[1,]
assert(maxerr<1e-10)
end
import delimited "tests/generated/expected_ci.csv", clear asdouble
mata: assert(max(abs(st_data(.,.)-CI))<1e-5)
display "TEST_PASS"
