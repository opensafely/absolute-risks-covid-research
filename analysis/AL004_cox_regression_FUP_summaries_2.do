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
*	Other output:	Log file:  logs/AL004_cox_regression_FUP_summaries_2.log
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
log using "logs/AL004_cox_regression_FUP_summaries_2", replace t


* Cycle over waves
forvalues i = 1 (1) 2 {
	
	* Open dataset (complete case ethnicity)
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	
	noi di _n(3) "____________________________________________________________"
	noi di _col(25) "Wave `i':"
	noi di "____________________________________________________________"
	
	noi di _n(1) "*** All data (irrespective of missing ethnicity data) ***"
	noi di _n(1)
	
	* Cycle over outcomes 
	foreach out in covidadmission coviddeath noncoviddeath {
		* Adults
		noi di "Adults: `out'"
		noi tab `out'`i' ldr if child==0
		* Children
		noi di "Children: `out'"
		tab `out'`i' ldr if child==1		
	}
	
	drop if ethnicity_5>=.
	noi di _n(1) "*** Complete case ethnicity data ***"
	noi di _n(1)
	
	* Cycle over outcomes 
	foreach out in covidadmission coviddeath noncoviddeath {
		* Adults
		noi di "Adults: `out'"
		noi tab `out'`i' ldr if child==0
		* Children
		noi di "Children: `out'"
		tab `out'`i' ldr if child==1		
	}
}

log close

