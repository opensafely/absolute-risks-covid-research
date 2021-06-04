********************************************************************************
*
*	Do-file:		AL004_cox_regression_FUP_summaries.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL004_cox_regression_FUP_summaries.log
*					Estimates:	output/AL004_cox_regression_FUP_summaries.out
*
* 						i = Wave (1 or 2)
*						out = outcome (coviddeath covidadmission)
*						exp = exposure (ldr ldr_cat ldr_carecat ds cp ldr_group)
*
********************************************************************************
*
*	Purpose:		This do-file fits a series of adjusted Cox models for the
*					learning disability work and obtains the crude rates.
*  
********************************************************************************





**************************
*  Adopath and log file  *
**************************

clear all
set more off

* Open a log file
cap log close
log using "logs/AL004_cox_regression_FUP_summaries", replace t



* Categories of various exposures
local lo_ldr 		= 0
local hi_ldr 		= 1
local lo_ldr_cat 	= 0
local hi_ldr_cat 	= 2
local hi_ldr 		= 1
local lo_ldr_carecat= 0
local hi_ldr_carecat= 2
local lo_ds 		= 0
local hi_ds 		= 1
local lo_cp 		= 0
local hi_cp 		= 1
local lo_ldr_group 	= 0
local hi_ldr_group 	= 5


* Open temporary file to post results
tempfile ldrfile
tempname ldrresults

postfile `ldrresults' 	wave str15(outcome) str15(exposure) expcat child ///
						p25 p50 p75 total using `ldrfile'

* Cycle over waves
forvalues i = 1 (1) 2 {
	
	* Open dataset (complete case ethnicity)
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	drop if ethnicity_5>=.

	* Cycle over outcomes 
	foreach out in covidadmission coviddeath {
		
		/*  Declare data to be survival  */

		stset stime_`out'`i', fail(`out'`i') scale(365.25)
		gen fup = ( _t - _t0)
		
		
		foreach exp in ldr ldr_cat ldr_carecat ds cp ldr_group  {

			/*  Summarise follow-up time  */
			
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
				* Adults
				summ fup if child==0 & `exp'==`k', detail
				post `ldrresults' (`i') ("`out'") ("`exp'") (`k') (0) (r(p25)) (r(p50)) (r(p75)) (r(sum))
				
				* Children
				summ fup if child==1 & `exp'==`k', detail
				post `ldrresults' (`i') ("`out'") ("`exp'") (`k') (1) (r(p25)) (r(p50)) (r(p75)) (r(sum))
			}
			
		}

		drop fup
	}
}

	
postclose `ldrresults'


use `ldrfile', clear
outsheet using "output/AL004_cox_regression_FUP_summaries.out", replace









*************************
*  Tidy output for HRs  *
*************************

* Outcome
rename outcome out
gen outcome 	= 1 if out=="coviddeath"
replace outcome = 2 if out=="covidadmission"

label define outcome 	1 "COVID-19 death" 		///
						2 "COVID-19 admission"	
label values outcome outcome
drop out

* Exposure
rename exposure exp
gen 	exposure = 1 if exp=="ldr"
replace exposure = 2 if exp=="ldr_cat"
replace exposure = 3 if exp=="ldr_carecat"
replace exposure = 4 if exp=="ds"
replace exposure = 5 if exp=="cp"
replace exposure = 6 if exp=="ldr_group"

label define exposure 	1 "Learning disability register"	///
						2 "LDR Severe vs mild"				///
						3 "LDR by residential care"			///
						4 "Down's syndrome"					///
						5 "Cerebral Palsy"					///
						6 "Combined grouping"				
label values exposure exposure						
drop exp

* Categories of exposure
gen category     = "No" 					if expcat==0
replace category = "Yes" 					if inlist(exposure, 1, 4, 5) & expcat==1

replace category = "LDR, mild" 				if inlist(exposure, 2) & expcat==1
replace category = "LDR, profound" 			if inlist(exposure, 2) & expcat==2

replace category = "LDR, community" 		if inlist(exposure, 3) & expcat==1
replace category = "LDR, residential care" 	if inlist(exposure, 3) & expcat==2

replace category = "DS but not LDR" 		if inlist(exposure, 6) & expcat==1
replace category = "DS and LDR" 			if inlist(exposure, 6) & expcat==2
replace category = "CP but not LDR" 		if inlist(exposure, 6) & expcat==3
replace category = "CP and LDR" 			if inlist(exposure, 6) & expcat==4
replace category = "LDR with no DS or CP" 	if inlist(exposure, 6) & expcat==5


order wave outcome exposure category total p*
sort wave outcome exposure expcat




log close

