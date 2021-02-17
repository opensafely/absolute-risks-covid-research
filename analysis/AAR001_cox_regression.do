********************************************************************************
*
*	Do-file:		AAR001_cox_regression.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_aranalysis_cohort1.dta
*							data_aranalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AAR001_cox_regression_wave`i'_`out'.log
*					Estimates:	output/
*									hr_wave`i'_male0_`out'.txt
*									hr_wave`i'_male1_`out'.txt
*
*									i=wave (1/2), 
*									out=coviddeath or covidadmission							
*
********************************************************************************
*
*	Purpose:		This do-file fits a multivariable Cox model for the
*					absolute risks work and tabulates estimated hazard ratios.
*  
********************************************************************************




**********************
*  Input parameters  *
**********************

local wave 		`1'
local outcome  	`2'

local i = `wave'
local out = "`outcome'"


noi di "Wave:" `i'
noi di "Outcome: `out'"



**************************
*  Adopath and log file  *
**************************

adopath ++ `c(pwd)'/analysis/ado

* Open a log file
cap log close
log using "logs/AAR001_cox_regression_wave`i'_`out'", replace t




***************
*  Open data  *
***************

* Open dataset
use "analysis/data_aranalysis_cohort`i'.dta", clear 

* Complete case ethnicity
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
				outputfile(output/hr_wave`i'_male`j'_`out'.txt)
}

log close
