********************************************************************************
*
*	Do-file:		AL012_MI_numbers.do
*
*	Programmed by:	Fizz 
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	analysis/
*							data_ldanalysis_cohort1_MI_child.dta
*							data_ldanalysis_cohort2_MI_child.dta
*
*	Other output:	Log file:  logs/AL010_MI_child.log
*
********************************************************************************
*
*	Purpose:		This do-file uses multiple imputation to handle missing 
*					data in the ethnicity variable for the learning disability 
*					work, for children.
*  
********************************************************************************



clear all
set more off

* Open a log file
cap log close
log using "logs/AL012_MI_numbers", replace t



/*  Children, wave 1  */

use "analysis/data_ldanalysis_cohort1_MI_child.dta", clear

noi count
tab child, m

tab ethnicity_5, m

forvalues i = 1 (1) 10 {
	noi tab _`i'_ethnicity_5, m
}

codebook age1 age2 age3 male obese40 imd stpcode household_id



/*  Children, wave 2  */

use "analysis/data_ldanalysis_cohort2_MI_child.dta", clear

count
tab child, m

tab ethnicity_5, m

forvalues i = 1 (1) 10 {
	noi tab _`i'_ethnicity_5, m
}

codebook age1 age2 age3 male obese40 imd stpcode household_id 





/*  Adults, wave 1  */

use "analysis/data_ldanalysis_cohort1_MI.dta", clear

noi count
tab child, m

tab ethnicity_5, m

forvalues i = 1 (1) 10 {
	noi tab _`i'_ethnicity_5, m
}

codebook age1 age2 age3 male imd stpcode household_id



/*  Adults, wave 2  */

use "analysis/data_ldanalysis_cohort2_MI.dta", clear

count
tab child, m

tab ethnicity_5, m

forvalues i = 1 (1) 10 {
	noi tab _`i'_ethnicity_5, m
}

codebook age1 age2 age3 male stpcode household_id imd	///
				obese40 									///
				respiratory asthma_severe					///
				cardiac af dvt_pe diabcat		 			///
				liver stroke tia dementia					///
				kidneyfn									///
				spleen transplant dialysis					///
				immunosuppression cancerHaem				///
				autoimmune ibd cancerExhaem1yr
				
				
				
				
log close
