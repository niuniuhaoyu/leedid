clear all
set more off
local source "`c(pwd)'"
capture mkdir "tests/generated/install"
net set ado "`source'/tests/generated/install"
net install leedid, from("`source'") replace
adopath - "."
adopath ++ "`source'/tests/generated/install"
findfile leedid.sthlp
findfile leedid_zh.sthlp
cd "tests/generated"
net get leedid, from("`source'") replace
do leedid_example.do
cd "`source'"
assert e(N_units)==1000
assert e(reps_success)==199
assert e(reps_failed)==0
matrix b=e(bounds)
assert !missing(b[1,6])
graph export "tests/generated/install-example.png", replace
file open helpfile using "`source'/leedid.sthlp", read
file close helpfile
display "TEST_PASS"
