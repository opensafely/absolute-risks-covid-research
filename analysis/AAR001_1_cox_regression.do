********************************************************************************
*
*	Do-file:		AAR001_1_cox_regression.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_aranalysis_cohort1.dta
*							data_aranalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AAR001_1_cox_regression.log
*					Estimates:	output/
*									hr_covidadmission_wave1_male0.txt
*									hr_covidadmission_wave1_male1.txt
*
********************************************************************************
*
*	Purpose:		This do-file fits a multivariable Cox model for the
*					absolute risks work and tabulates estimated hazard ratios.
*  
********************************************************************************


* Set wave (1 or 2), outcome (coviddeath, covidadmission or composite)
local i = 1
local out = "covidadmission"


clear all
set more off

* Open a log file
cap log close
log using "logs/AAR001_1_cox_regression", replace t



* Open dataset (complete case ethnicity)
use "analysis/data_aranalysis_cohort`i'.dta", clear 
drop if ethnicity_5>=.


* Keep under 50s only
drop if age>=50



/*  Declare data to be survival  */

stset stime_`out'`i', fail(`out'`i') scale(365.25)


		
/*  Fit Cox models  */
			
forvalues j = 0 (1) 1 {
	capture erase coefs_cox_1_`j'.ster

	stcox 		age1 age2 age3					///
				ib2.obesecat					///
				i.smoke_nomiss					///
				i.ethnicity_5					///
				i.imd 							///
				i.respiratory 					///
				i.cf 							///
				i.asthmacat						///
				i.cardiac						///
				i.hypertension					///
				i.diabcat						///
				i.af							///
				i.dvt_pe						///
				i.pad							///
				i.cancerExhaem	 				///
				i.cancerHaem 					///
				i.liver					 		///
				i.stroke		 				///
				i.dementia				 		///
				i.tia					 		///
				i.neuro							///
				i.kidneyfn						///
				i.transplant 					///
				i.dialysis 						///
				i.spleen 						///
				i.autoimmune  					///
				i.ibd		  					///
				i.immunosuppression				///
				i.smi							///
				i.ds							///
				i.ldr							///
				i.fracture						///
				if male==`j'					///
				, strata(stp)
	estimates save coefs_cox_1_`j', replace
}




*********************************************
*  Read in estimates and format for tables  *
*********************************************

* Read in programs to format output
qui do "analysis/000_HR_table.do"

forvalues j = 0 (1) 1 {
	* Cox model
	crtablehr, 	estimates(coefs_cox_1_`j')		///
				outputfile(output/hr_`out'_wave`i'_male`j'.txt)
}

log close