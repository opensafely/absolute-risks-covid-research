********************************************************************************
*
*	Do-file:		AR001b_tabulate_cohort_descriptives.do
*
*	Programmed by:	Fizz (based on Krishnan's files)
*
*	Data used:		analysis/
*						data_aranalysis_cohort1.dta
*
*	Data created:	None
*
*	Other output:	Table: 		output/basetable1_ar.txt
*					Log file: 	logs/AR001b_tabulate_cohort_descriptives.log
*
********************************************************************************
*
*	Purpose:		This do-file describes the data in the base cohort and 
*					puts the output in a log file.
*  
********************************************************************************* 



* Open a log file
cap log close
log using "logs/AR001b_tabulate_cohort_descriptives", text replace 

* Add ado files
adopath++ `c(pwd)'\analysis


*************************************************
*   Program: generaterow 						*
*												*
*	Generic code to output one row of table		*
*************************************************

cap prog drop generaterow
program define generaterow
syntax, variable(varname) binexp(varname) condition(string) file(string)
	
	* Counts among exposed
	safecount if `binexp'==1
	local expdenom = r(N)
	safecount if `variable' `condition' & `binexp'==1
	file write `file' ("`variable'") _tab ("`condition'") _tab (r(N)) (" (") %2.0f (100*(r(N))/`expdenom') (")") _tab

	* Counts among unexposed
	safecount if `binexp'==0
	local unexpdenom = r(N)
	safecount if `variable' `condition' & `binexp'==0
	file write `file' (r(N)) (" (") %2.0f (100*(r(N))/`unexpdenom') (")") _n

end




*************************************************
*   Program: tabulatevariable					*
*												*
*	Generic code to output one section 			*
*   (variable) within table						*
*************************************************


cap prog drop tabulatevariable
prog define tabulatevariable
	syntax, variable(varname) binexp(varname) ///
		start(real) end(real) [missing] file(string)

	foreach varlevel of numlist `start'/`end'{ 
		generaterow, variable(`variable') binexp(`binexp') ///
			condition("==`varlevel'") file(`file')
	}
	if "`missing'"!="" generaterow, ///
		variable(`variable') binexp(`binexp')  ///
			condition(">=.") file(`file')

end





*************************
*  Create table output  *
*************************



cap file close tablecontent
file open tablecontent using "output/basetable1_ar.txt", write text replace



/*  Open cohort and extract covariates  */
	
use "analysis/data_aranalysis_cohort1.dta", clear 

* Complete case for ethnicity  
drop if ethnicity_5>=.

* Keep adults 18-50 only
keep if inrange(age, 18, 50)


/* Table: Demographic variables  */

gen byte cons=1
tabulatevariable, variable(cons) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

tabulatevariable, variable(agegroup) start(1) end(7) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

tabulatevariable, variable(male) start(0) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

tabulatevariable, variable(ethnicity_5) start(1) end(5) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

tabulatevariable, variable(region_7) start(1) end(7) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

tabulatevariable, variable(imd) start(1) end(5) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

tabulatevariable, variable(obesecat) start(1) end(5) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

tabulatevariable, variable(smoke_nomiss) start(1) end(3) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 



/* Table: Comorbidities  */

tabulatevariable, variable(asthmacat) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(cf) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(respiratory) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(cardiac) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(af) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(dvt_pe) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(pad) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(diabcat) start(2) end(4) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(liver) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(stroke) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(tia) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(dementia) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(neuro) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(kidneyfn) start(2) end(3) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(spleen) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(transplant) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(immunosuppression) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(cancerHaem) start(2) end(4) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(cancerExhaem) start(2) end(4) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(autoimmune) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(ibd) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(smi) start(1) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(ld) start(0) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 
tabulatevariable, variable(ds) start(0) end(1) file(tablecontent) binexp(coviddeath2_nocensor)
file write tablecontent _n 

file close tablecontent


* Close log
log close

