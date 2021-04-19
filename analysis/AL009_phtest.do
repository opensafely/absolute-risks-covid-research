********************************************************************************
*
*	Do-file:		AL009_phtest.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL009_phtest.log
*					Estimates:	output/
*
********************************************************************************
*
*	Purpose:		This do-file test the proportional hazards assumption
*					for the main Cox models for the learning disability work.
*  
********************************************************************************



clear all
set more off

* Open a log file
cap log close
log using "logs/AL009_phtest", replace t


forvalues i = 1 (1) 2 {


	* Open dataset (complete case ethnicity)
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	drop if ethnicity_5>=.

	* Only keep data for adults
	keep if child==0

	foreach out in covidadmission coviddeath {
			
		/*  Declare data to be survival  */

		stset stime_`out'`i', fail(`out'`i') scale(365.25)


		/*  Fit Cox model  */
			
		* Confounder only model
		stcox i.ldr age1 age2 age3 male i.ethnicity_5, 		///
			strata(stpcode) cluster(household_id) 
			
			
		/*  PH test  */
		
		* Global test for PH
		estat phtest, detail

	}
}

log close

