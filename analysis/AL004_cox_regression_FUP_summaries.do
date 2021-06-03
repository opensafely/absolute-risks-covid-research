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

* Open temporary file to post results
tempfile ldrfile
tempname ldrresults

postfile `ldrresults' 	wave str15(outcome) child ///
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
		
		
		/*  Summarise follow-up time  */
		
		* Adults
		summ fup if child==0, detail
		post `ldrresults' (`i') ("`out'") (0) (r(p25)) (r(p50)) (r(p75)) (r(sum))
		
		* Children
		summ fup if child==1, detail
		post `ldrresults' (`i') ("`out'") (1) (r(p25)) (r(p50)) (r(p75)) (r(sum))
		
		drop fup
	}
}

	
postclose `ldrresults'


use `ldrfile', clear
outsheet using "output/AL004_cox_regression_FUP_summaries.out", replace


log close

