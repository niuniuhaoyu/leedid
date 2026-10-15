* Run from the repository root. Clears current data.
version 16.0
adopath ++ "."
do examples/leedid_simdata.do
leedid y, unit(id) time(period) treat(treated) selection(s1 s2) ///
    directions(1 -1) reps(199) seed(285) graph
matrix list e(selection)
matrix list e(qtt)
