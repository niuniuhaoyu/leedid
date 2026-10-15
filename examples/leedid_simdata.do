* Simulated data only. Running this example clears the current data.
version 16.0
clear
set more off
set seed 1803
set obs 1000
gen long id=_n
gen byte treated=id>500
gen double y0=runiform()*5
gen double y1=y0+.4+treated*(.7+.1*y0)+rnormal()*.25
gen double u=runiform()
gen byte cause=0
replace cause=1 if u<cond(treated,.08,.20)
replace cause=2 if u>=cond(treated,.08,.20) & u<.28
expand 2
bysort id: gen byte period=_n
gen byte s1=!(period==2 & cause==1)
gen byte s2=!(period==2 & cause==2)
gen double y=cond(period==1,y0,y1)
replace y=. if s1*s2==0
capture mkdir data
save data/leedid_sim.dta, replace
