********************************************************************************
*
*	Do-file:		AL001_describe_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta
*
*	Data created:	None
*
*	Other output:	Log file:  output/AL001_describe_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file describes the data in the analysis datasets and 
*					puts the output in a log file.
*  
********************************************************************************* 


clear all
set more off


* Open a log file
cap log close
log using "logs/AL001_describe_cohort", replace text



* Wave 1: i=1  (1 Mar 20 - 31 Aug 20) 
* Wave 2: i=2  (1 Sept 20 - latest)
forvalues i = 1 (1) 2 {
	 
		
	/* Open base cohort   */ 

	use "analysis/data_ldanalysis_cohort`i'.dta", clear 

		
	/* Complete case for ethnicity   */ 

	tab ethnicity_5
	tab ethnicity_5, m
	drop if ethnicity_5>=.



		

	*********************************
	*  Describe exposure variables  *
	*********************************

	tab ldr
	tab ld_profound ldr, m
	tab ldr_cat
	tab ldr_carecat ldr, m
	tab ldr_carecat

	tab ds ldr, m
	tab ds

	tab cp ldr, m
	tab cp

	tab ldr_group ldr, m
	tab ldr_group cp,  m
	tab ldr_group ds,  m
	tab ldr_group 

	


	***********************************
	*  Describe confounder variables  *
	***********************************

	* Area
	tab region_7, 		m
	tab stp,		 	m

	* Age, sex and ethnicity
	summ age, 			d 
	tab agegroup, 		m
	tab child, 			m
	bysort child: summ age, d
	tab male, 			m

	* Ethnicity
	tab ethnicity_5, 	m
	tab ethnicity_16, 	m

	


	********************************************
	*  Describe potential mediators variables  *
	********************************************

	* Deprivation
	tab imd, 			m

	
	* Residential care 
	tab resid_care_old,	m
	tab resid_care_ldr,	m
	sum household_size, d
	tab resid_care_old resid_care_ldr
	

	
	
	*******************************************
	*  Describe comorbidities (adjusted for)  *
	*******************************************
	
	* BMI
	summ bmi, 			d
	tab obese40, 		m

	
	* Physical comorbidities, also indicators for vaccination
	tab1 	asthma_severe cf respiratory		///
			cardiac  af dvt_pe diabcat		 	///
			liver stroke tia dementia			///
			kidneyfn, m

			
	* Indicators for immunosuppression (an indication for vaccination)
	tab1 	spleen transplant dialysis			///
			immunosuppression cancerHaem		///
			autoimmune ibd cancerExhaem1yr, m

	
	
	*****************************************************
	*  Describe other vaccine priority group variables  *
	*****************************************************
	
	tab1 smi neuro dialysis, m
	

			
	********************************
	*  Describe outcome variables  *
	********************************
		
	summ coviddeath_date otherdeath_date covidadmission_date composite_date, d format

	if `i'==1 {	
		tab coviddeath1 
		tab covidadmission1 
		tab coviddeath1 covidadmission1
		tab composite1
	}
	tab coviddeath2 
	tab covidadmission2 
	tab coviddeath2 covidadmission2
	tab composite2


	summ stime*

}

* Close log file
log close



