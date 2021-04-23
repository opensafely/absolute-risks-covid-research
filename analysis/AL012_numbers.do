********************************************************************************
*
*	Do-file:		AL004_cox_regression.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL004_cox_regression_wave`i'_`out'_MI.log
*					Estimates:	output/
*									ldcox_wave`i'_`out'_MI.out
*
* 						i = Wave (1 or 2)
*						out = outcome (coviddeath covidadmission)
*
********************************************************************************
*
*	Purpose:		This do-file fits a series of adjusted Cox models for the
*					learning disability work and obtains the crude rates
*					in the multiply imputed data (for ethnicity).
*  
********************************************************************************




**************************
*  Adopath and log file  *
**************************

clear all
set more off

* Open a log file
cap log close
log using "logs/AL012_numbers", replace t


forvalues i = 1 (1) 2 {

	* Open dataset
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	gen cons = 1

	forvalues j = 0 (1) 1 {
	
		if `j'==0 {
			noi di "FULL SAMPLE: "
		}
		else if `j'==1 {
			noi drop if ethnicity_5>=.
			noi di "COMPLETE CASE ETHNICITY SAMPLE: "
		}
		
		/*  Adults  */
		
		noi di _n "ADULTS:"
		
		* Number of people
		qui count if child==0
		noi di "Total" _col(40) = r(N)
		
		* Person-years of follow-up
		summ stime_coviddeath`i' if child==0
		noi di "Total follow-up in years" _col(40) = r(sum)/365.25
		
		* COVID-19 deaths
		qui count if coviddeath`i'==1 & child==0
		noi di "COVID-19 deaths" _col(40) = r(N)
		
		* COVID-19 hospital admissions
		qui count if covidadmission`i'==1 & child==0
		noi di "COVID-19 hospital admissions" _col(40) = r(N)
		
		
		
		/*  Children  */
		
		noi di _n "CHILDREN:"
		
		* Number of people
		qui count if child==1
		noi di "Total" _col(40) = r(N)
				
		* Person-years of follow-up
		summ stime_coviddeath`i' if child==1
		noi di "Total follow-up in years" _col(40) = r(sum)/365.25
		
		* COVID-19 deaths
		qui count if coviddeath`i'==1 & child==1
		noi di "COVID-19 deaths" _col(40) = r(N)
		
		* COVID-19 hospital admissions
		qui count if covidadmission`i'==1 & child==1
		noi di "COVID-19 hospital admissions" _col(40) = r(N)
	
		
		/*  In subgroups  */
			
		* Adults
		noi bysort cons:	 	tab ldr coviddeath`i' if child==0
		noi bysort agebroad: 	tab ldr coviddeath`i' if child==0 
		noi bysort male: 	 	tab ldr coviddeath`i' if child==0 
		noi bysort imd: 		tab ldr coviddeath`i' if child==0 
		noi bysort ethnicity_5: tab ldr coviddeath`i' if child==0 
		
		noi bysort cons:	 	tab ldr covidadmission`i' if child==0
		noi bysort agebroad: 	tab ldr covidadmission`i' if child==0 
		noi bysort male: 	 	tab ldr covidadmission`i' if child==0 
		noi bysort imd: 		tab ldr covidadmission`i' if child==0 
		noi bysort ethnicity_5: tab ldr covidadmission`i' if child==0 
		
		* Children
		noi bysort cons:	 	tab ldr coviddeath`i' if child==1
		noi bysort agebroad: 	tab ldr coviddeath`i' if child==1 
		noi bysort male: 	 	tab ldr coviddeath`i' if child==1 
		noi bysort imd: 		tab ldr coviddeath`i' if child==1 
		noi bysort ethnicity_5: tab ldr coviddeath`i' if child==1 

		noi bysort cons:	 	tab ldr covidadmission`i' if child==1
		noi bysort agebroad: 	tab ldr covidadmission`i' if child==1 
		noi bysort male: 	 	tab ldr covidadmission`i' if child==1 
		noi bysort imd: 		tab ldr covidadmission`i' if child==1 
		noi bysort ethnicity_5: tab ldr covidadmission`i' if child==1 
	}
}

log close

