********************************************************************************
*
*	Do-file:		AL010_MI.do
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
log using "logs/AL010_MI_child", replace t



/*  Adults  */

forvalues i = 1 (1) 2 {

	* Open dataset
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	
	* Only keep adults
	keep if child==1
	
	
	* Ethnicity variable
	drop ethnicity_16
	replace ethnicity_5 = . if ethnicity_5>=.
	
	foreach out in covidadmission {
			
		/*  Declare data to be survival  */

		stset stime_`out'`i', fail(`out'`i') scale(365.25)

		* Obtain Nelson-Aalen estimate of Cumulative Hazard
		sts generate cumh_`out' = na, by(child)
		egen cumhgp_`out' = cut(cumh_`out'), group(5)
		replace cumhgp_`out' = cumhgp_`out' + 1
	}
	
	tab cumhgp_covidadmission, m

	mi set wide
	mi register imputed ethnicity_5

	* Check estimated cumulative hazards are non-missing
	count if cumhgp_covidadmission>=.
	replace cumhgp_covidadmission = 0 if cumhgp_covidadmission==.

	* Check relevant variables are fully observed 
	recode asthma_severe .=0
	foreach var of varlist stp						///
		cumhgp_covidadmission						///
		covidadmission`i' 							///
		ldr_cat resid_care_ldr ds cp				///
		age1 age2 age3 male obese40  {
			assert `var'<.
	}
		
	
	* Multinomial logistic regression model for ethnicity
	mi impute mlogit ethnicity_5					///
		= i.stp										///
		i.cumhgp_covidadmission						///
		covidadmission`i' 							///
		i.ldr_cat resid_care_ldr ds cp				///
		age1 age2 age3 male obese40,				///
		add(10) rseed(3040985) augment
		
	* Save imputed dataset
	save "analysis/data_ldanalysis_cohort`i'_MI_child.dta", replace 

}

