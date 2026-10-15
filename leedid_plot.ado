*! leedid_plot 0.1.0 15oct2026
program define leedid_plot
    version 16.0
    syntax [, NAME(string)]
    if "`e(cmd)'"!="leedid" error 301
    if "`name'"=="" local name leedid_qtt
    tempname Q
    matrix `Q'=e(qtt)
    preserve
    clear
    quietly svmat double `Q', names(col)
    twoway (rarea lower upper quantile, color(navy%18) lwidth(none)) ///
        (line lower upper quantile, lcolor(navy navy)) ///
        (line ci_lower ci_upper quantile, lcolor(gs6 gs6) lpattern(dash dash)), ///
        yline(0, lcolor(gs10)) xtitle("Quantile") ytitle("AO quantile treatment effect") ///
        title("CiC selection bounds") ///
        legend(order(1 "Identified interval" 4 "Pointwise parameter CI")) ///
        note("Viviens (2026). Intervals are pointwise, not simultaneous bands.") ///
        name(`name', replace) graphregion(color(white))
    restore
end
