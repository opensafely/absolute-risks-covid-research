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
*									output_hrs_mainAL004_`i'_`out'_`exp'
*									output_rates_`i'_`out'_`exp'
*
********************************************************************************
*
*	Purpose:		This do-file fits a series of adjusted Cox models for the
*					learning disability work and obtains the crude rates.
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


/*  Declare data to be survival  */

stset stime_`out'`i', fail(`out'`i') scale(365.25)


		
/*  Fit Cox models  */
			
* Confounder only model
stcox 		age1 age2 age3					///
			i.male 							///
			i.obesecat						///
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
			, strata(stp)
		
log close
