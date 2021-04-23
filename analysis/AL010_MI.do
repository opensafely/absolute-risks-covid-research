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
*							data_ldanalysis_cohort1_MI.dta
*							data_ldanalysis_cohort2_MI.dta
*
*	Other output:	Log file:  logs/AL009_phtest.log
*
********************************************************************************
*
*	Purpose:		This do-file uses multiple imputation to handle missing 
*					data in the ethnicity variable for the learning disability 
*					work.
*  
********************************************************************************



clear all
set more off

* Open a log file
cap log close
log using "logs/AL010_MI", replace t



/*  Adults  */

forvalues i = 1 (1) 2 {

	* Open dataset
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 

	* Ethnicity variable
	drop ethnicity_16
	replace ethnicity_5 = . if ethnicity_5>=.
	gen ethnicity_5_child = ethnicity_5 if child==1
	gen ethnicity_5_adult = ethnicity_5 if child==0
	drop ethnicity_5
	
	replace ethnicity_5_adult = 999 if child==1
	replace ethnicity_5_child = 999 if child==0
	
	
	foreach out in covidadmission coviddeath {
			
		/*  Declare data to be survival  */

		stset stime_`out'`i', fail(`out'`i') scale(365.25)

		* Obtain Nelson-Aalen estimate of Cumulative Hazard
		sts generate cumh_`out' = na, by(child)
		egen cumhgp_`out'_0 = cut(cumh_`out') if child==0, group(5)
		egen cumhgp_`out'_1 = cut(cumh_`out') if child==1, group(5)
		gen 	cumhgp_`out' = cumhgp_`out'_0 if child==0
		replace cumhgp_`out' = cumhgp_`out'_1 if child==1
		replace cumhgp_`out' = cumhgp_`out' + 1
	}
	
	tab cumhgp_coviddeath 		child, m
	tab cumhgp_covidadmission 	child, m

	mi set wide
	mi register imputed ethnicity_5_child ethnicity_5_adult

	* Check estimated cumulative hazards are non-missing
	count if cumhgp_coviddeath>=.
	replace cumhgp_coviddeath = 0 if cumhgp_coviddeath==.
	count if cumhgp_covidadmission>=.
	replace cumhgp_covidadmission = 0 if cumhgp_covidadmission==.

	* Check relevant variables are fully observed 
	recode asthma_severe .=0
	foreach var of varlist stp						///
		cumhgp_coviddeath cumhgp_covidadmission		///
		coviddeath`i' covidadmission`i' 			///
		ldr_cat resid_care_ldr ds cp				///
		age1 age2 age3 male obese40 				///
		respiratory asthma_severe					///
		cardiac af dvt_pe diabcat		 			///
		liver stroke tia dementia					///
		kidneyfn									///
		spleen transplant dialysis					///
		immunosuppression cancerHaem				///
		autoimmune ibd cancerExhaem1yr {
			assert `var'<.
	}
		
	
	* Multinomial logistic regression model for ethnicity
	mi impute chained 								///
		(mlogit, cond(if child==1) 					///
		omit(coviddeath`i' i.cumhgp_coviddeath		///
		respiratory asthma_severe					///
		cardiac af dvt_pe i.diabcat		 			///
		liver stroke tia dementia					///
		i.kidneyfn									///
		spleen transplant dialysis					///
		immunosuppression i.cancerHaem				///
		autoimmune ibd cancerExhaem1yr)) 			/// 
		ethnicity_5_child 							///
		(mlogit, cond(if child==0))					///
		ethnicity_5_adult							///
		= i.stp										///
		i.cumhgp_coviddeath	i.cumhgp_covidadmission	///
		coviddeath`i' covidadmission`i' 			///
		i.ldr_cat resid_care_ldr ds cp				///
		age1 age2 age3 male obese40 				///
		respiratory asthma_severe					///
		cardiac af dvt_pe i.diabcat		 			///
		liver stroke tia dementia					///
		i.kidneyfn									///
		spleen transplant dialysis					///
		immunosuppression i.cancerHaem				///
		autoimmune ibd cancerExhaem1yr,				///
		add(10) rseed(3040985) noimputed augment
		
	* Save imputed dataset
	save "analysis/data_ldanalysis_cohort`i'_MI.dta", replace 

}

