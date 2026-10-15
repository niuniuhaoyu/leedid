*! leedid 0.1.0 15oct2026 -- Haoyu Niu
program define leedid, eclass sortpreserve
    version 16.0
    syntax varname(numeric) [if] [in], UNIT(varname) TIME(varname numeric) ///
        TREAT(varname numeric) SELection(varlist numeric) DIREctions(numlist) ///
        [PRE(real -999999) POST(real -999999) PROBS(numlist >0 <1) ///
        REPS(integer 199) SEED(integer -1) Level(cilevel) CLuster(varname) GRAPH]
    local y `varlist'
    local J : word count `selection'
    local K : word count `directions'
    if `J'!=`K' {
        di as error "directions() must supply one 1 or -1 per selection source"
        exit 198
    }
    foreach d of numlist `directions' {
        if !inlist(`d',-1,1) exit 198
    }
    if `reps'<0 | `reps'==1 | `seed'<-1 exit 198
    if `reps'>0 & `seed'>=0 quietly set seed `seed' 
    if "`probs'"=="" numlist ".1(.1).9"
    if "`probs'"=="" local probs `r(numlist)'
    marksample touse, novarlist
    quietly count if `touse'
    if r(N)==0 error 2000
    foreach v in `unit' `time' `treat' `selection' `cluster' {
        quietly count if `touse' & missing(`v')
        if r(N)>0 {
            di as error "Missing `v' in the analysis roster; do not delete attrited units"
            exit 459
        }
    }
    if (`pre'==-999999)!=(`post'==-999999) {
        di as error "Specify both pre() and post(), or neither"
        exit 198
    }
    if `pre'==-999999 {
        quietly levelsof `time' if `touse', local(periods)
        local nt : word count `periods'
        if `nt'!=2 {
            di as error "Choose exactly two periods using pre() and post()"
            exit 198
        }
        local pre : word 1 of `periods'
        local post : word 2 of `periods'
    }
    if `pre'>=`post' exit 198
    quietly replace `touse'=0 if !inlist(`time',`pre',`post')
    preserve
    quietly keep if `touse'
    quietly count
    if r(N)==0 error 2000
    local N=r(N)
    isid `unit' `time'
    sort `unit' `time'
    tempvar n same joint zeros
    quietly by `unit': gen long `n'=_N
    quietly count if `n'!=2
    if r(N)>0 {
        di as error "Each unit needs both roster rows, including rows with missing outcomes"
        exit 459
    }
    quietly count if !inlist(`treat',0,1)
    if r(N)>0 exit 459
    quietly by `unit': gen byte `same'=(`treat'==`treat'[1])
    quietly count if !`same'
    if r(N)>0 {
        di as error "treat() must be a time-invariant 0/1 group indicator"
        exit 459
    }
    if "`cluster'"!="" {
        quietly by `unit': replace `same'=(`cluster'==`cluster'[1])
        quietly count if !`same'
        if r(N)>0 exit 459
    }
    quietly gen byte `joint'=1
    quietly gen int `zeros'=0
    foreach s of varlist `selection' {
        quietly count if !inlist(`s',0,1)
        if r(N)>0 exit 459
        quietly by `unit': replace `same'=(`s'[2]<=`s'[1])
        quietly count if !`same'
        if r(N)>0 {
            di as error "Selection-source re-entry is outside this implementation's absorbing design"
            exit 459
        }
        quietly replace `joint'=`joint'*`s'
        quietly replace `zeros'=`zeros'+(`s'==0)
    }
    quietly count if `zeros'>1
    if r(N)>0 {
        di as error "Multiple selection causes must be mutually exclusive (at most one zero per row)"
        exit 459
    }
    quietly count if `joint'==1 & missing(`y')
    if r(N)>0 {
        di as error "Outcome is missing on rows declared observed by all selection sources"
        exit 459
    }
    capture mata: _ld_version()
    if _rc {
        findfile leedid_mata.ado
        quietly do "`r(fn)'"
    }
    tempvar clid
    if "`cluster'"=="" quietly egen long `clid'=group(`unit')
    else quietly egen long `clid'=group(`cluster')
    tempname bounds qtt meta b detail V boot bootq
    mata: _ld_run("`treat' `y' `selection'", "`directions'", "`probs'", "`bounds'", "`qtt'", "`meta'", "`b'", "`detail'", "`clid'", `reps', `level'/100, "`V'", "`boot'", "`bootq'")
    restore
    matrix colnames `bounds'=complete_case lower upper se_lower se_upper ci_lower ci_upper
    matrix rownames `bounds'=DID CIC
    matrix colnames `qtt'=quantile lower upper se_lower se_upper ci_lower ci_upper
    matrix colnames `detail'=source group baseline observed counterfactual
    matrix colnames `b'=did_lower did_upper cic_lower cic_upper
    if `reps'>0 & `meta'[1,8]==0 {
        matrix colnames `V'=did_lower did_upper cic_lower cic_upper
        matrix rownames `V'=did_lower did_upper cic_lower cic_upper
        ereturn post `b' `V', esample(`touse') obs(`N')
    }
    else ereturn post `b', esample(`touse') obs(`N')
    if `reps'>0 {
        matrix colnames `boot'=did_lower did_upper cic_lower cic_upper
        ereturn matrix boot=`boot'
        ereturn matrix boot_qtt=`bootq'
    }
    ereturn scalar N_clusters=`meta'[1,6]
    ereturn scalar reps_success=`meta'[1,7]
    ereturn scalar reps_failed=`meta'[1,8]
    ereturn scalar boot_projected=`meta'[1,9]
    ereturn local clustvar "`cluster'"
    ereturn matrix bounds=`bounds'
    ereturn matrix qtt=`qtt'
    ereturn matrix selection=`detail'
    ereturn scalar pi0=`meta'[1,1]
    ereturn scalar pi1=`meta'[1,2]
    ereturn scalar N_control=`meta'[1,3]
    ereturn scalar N_treated=`meta'[1,4]
    ereturn scalar N_units=`N'/2
    ereturn scalar projected=`meta'[1,5]
    ereturn scalar reps=`reps'
    ereturn scalar level=`level'
    ereturn local cmd "leedid"
    ereturn local depvar "`y'"
    ereturn local selection_vars "`selection'"
    ereturn local directions "`directions'"
    ereturn local title "Selection-adjusted DID / CiC bounds (Viviens)"
    di as text "Always-observed shares: control = " as result %7.4f e(pi0) as text "; treated = " as result %7.4f e(pi1)
    matlist e(bounds), format(%10.5f) title("Average effects: identified bounds and pointwise parameter CIs")
    if e(projected)>0 di as text "Note: AO share(s) above one projected to one; inspect e(selection) and directions()."
    if e(reps_failed)>0 di as error "Bootstrap draws undefined: " e(reps_failed) "; all SEs/CIs withheld. Inspect selection and cluster support."
    if e(boot_projected)>0 di as text "Bootstrap draws with AO projection: " e(boot_projected) ". Inference at selection boundaries may be nonregular."
    if "`graph'"!="" leedid_plot
end
