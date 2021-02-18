********************************************************************************
*
*	Do-file:		AAR001_describe_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		analysis/
*						data_aranalysis_cohort1.dta (Wave 1)
*						data_aranalysis_cohort2.dta (Wave 2)
*
*	Data created:	None
*
*	Other output:	Log file:  output/AAR001_describe_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file describes the data in the analysis datasets for 
*					the absolute risks work, and puts the output in a log file.
*  
********************************************************************************* 


clear all
set more off

	
* Open a log file
cap log close
log using "logs/AAR001_describe_cohort", replace text


* Add ado files
adopath++ `c(pwd)'\analysis


* Wave 1: i=1  (1 Mar 20 - 31 Aug 20) 
* Wave 2: i=2  (1 Sept 20 - latest)
forvalues i = 1 (1) 2 {
	 
		
	/* Open base cohort   */ 

	use "analysis/data_aranalysis_cohort`i'.dta", clear 

		
	/* Complete case for ethnicity   */ 

	safetab ethnicity_5
	safetab ethnicity_5, m
	drop if ethnicity_5>=.


						
	********************************
	*  Describe outcome variables  *
	********************************
		
	summ coviddeath_date otherdeath_date covidadmission_date composite_date, d format

	if `i'==1 {	
		safetab coviddeath1 
		safetab covidadmission1 
		safetab coviddeath1 covidadmission1
		safetab composite1
		safetab coviddeath1_nocensor
		safetab covidadmission1_nocensor
		safetab coviddeath1_nocensor covidadmission1_nocensor
		safetab coviddeath1			coviddeath1_nocensor
		safetab covidadmission1	 	covidadmission1_nocensor
		
		bysort coviddeath1: 			 summ stime_coviddeath1
		bysort covidadmission1: 		 summ stime_covidadmission1
		bysort coviddeath1_nocensor: 	 summ stime_coviddeath1_nocensor
		bysort covidadmission1_nocensor: summ stime_covidadmission1_nocensor
	}
	safetab coviddeath2 
	safetab covidadmission2 
	safetab coviddeath2 covidadmission2
	safetab composite2
	safetab coviddeath2_nocensor
	safetab covidadmission2_nocensor
	safetab coviddeath2_nocensor covidadmission2_nocensor

	summ stime*
	
	bysort coviddeath2: 			 summ stime_coviddeath2
	bysort covidadmission2: 		 summ stime_covidadmission2
	bysort coviddeath2_nocensor: 	 summ stime_coviddeath2_nocensor
	bysort covidadmission2_nocensor: summ stime_covidadmission2_nocensor

	
	

	************************************
	*  Describe demographic variables  *
	************************************

	* Area
	safetab region_7, 		m
	safetab stp,		 	m

	* Age, sex and ethnicity
	summ age, 			d 
	safetab agegroup, 	m
	safetab male, 		m

	* Ethnicity
	safetab ethnicity_5, 	m

	* Deprivation
	safetab imd, 			m


	* Obesity
	summ bmi, 			d
	safetab obesecat,	m
	
	
	
	*****************************
	*  Describe comorbidities   *
	*****************************
	
	
	* Physical comorbidities, also indicators for vaccination
	foreach var of varlist asthmacat cf respiratory		///
			cardiac af dvt_pe diabcat		 			///
			 stroke tia dementia neuro					///
			kidneyfn transplant dialysis liver 			///
			cancerHaem cancerExhaem 					///
			immunosuppression spleen autoimmune ibd		///
			smi ldr ds fracture							///
			{
			safetab `var', m
	}
			
			


}

* Close log file
log close



