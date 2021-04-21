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


* Add ado files
adopath++ `c(pwd)'\analysis\ado


* Wave 1: i=1  (1 Mar 20 - 31 Aug 20) 
* Wave 2: i=2  (1 Sept 20 - latest)
forvalues i = 1 (1) 2 {
	 
		
	/* Open base cohort   */ 

	use "analysis/data_ldanalysis_cohort`i'.dta", clear 

		
	/* Complete case for ethnicity   */ 

	safetab ethnicity_5
	safetab ethnicity_5, m
	
	
	* Missing BMI 
	summ bmi, 			d
	safetab obese40, 	m
	qui gen bmi_miss = missing(bmi)
	noi tab bmi_miss 
	
	* Missing Hba1c (among diabetics)
	qui gen hba1c_miss = missing(hba1c)
	noi tab hba1c_miss if diabcat!=1
	
	* Missing Estimated GFR
	qui gen egfr_miss = missing(egfr)
	noi tab egfr_miss 
	
	* Restrict to complete case ethnicity sample
	drop if ethnicity_5>=.



		

	*********************************
	*  Describe exposure variables  *
	*********************************

	safetab ldr
	safetab ld_profound ldr, m
	safetab ldr_cat
	safetab ldr_carecat ldr, m
	safetab ldr_carecat

	safetab ds ldr, m
	safetab ds

	safetab cp ldr, m
	safetab cp

	safetab ldr_group ldr, m
	safetab ldr_group cp,  m
	safetab ldr_group ds,  m
	safetab ldr_group 

	


	***********************************
	*  Describe confounder variables  *
	***********************************

	* Area
	safetab region_7, 		m
	safetab stp,		 	m

	* Age, sex and ethnicity
	summ age, 			d 
	safetab agegroup, 	m
	safetab child, 		m
	bysort child: summ age, d
	safetab male, 		m

	* Ethnicity
	safetab ethnicity_5, 	m
	safetab ethnicity_16, 	m

	


	********************************************
	*  Describe potential mediators variables  *
	********************************************

	* Deprivation
	safetab imd, 			m

	
	* Residential care 
	safetab resid_care_old,	m
	safetab resid_care_ldr,	m
	sum household_size, d
	safetab resid_care_old resid_care_ldr
	
	safetab resid_care_old ldr,	m
	safetab resid_care_ldr ldr,	m
	
	
	
	
	*******************************************
	*  Describe comorbidities (adjusted for)  *
	*******************************************
	
	* BMI
	summ bmi, 			d
	safetab obese40, 	m
	qui gen bmi_miss = missing(bmi)
	noi tab bmi_miss 
	
	* Hba1c
	qui gen hba1c_miss = missing(hba1c)
	noi tab hba1c_miss if diabcat!=1
	
	* Estimated GFR
	qui gen egfr_miss = missing(egfr)
	noi tab egfr_miss 
	
	* Physical comorbidities, also indicators for vaccination
	foreach var of varlist asthma_severe cf respiratory		///
			cardiac  af dvt_pe diabcat		 				///
			liver stroke tia dementia						///
			kidneyfn {
			safetab `var', m
	}
			
	* Indicators for immunosuppression (an indication for vaccination)
	foreach var of varlist spleen transplant dialysis		///
			immunosuppression cancerHaem					///
			autoimmune ibd cancerExhaem1yr {
			safetab `var', m
	}
	
	
	*****************************************************
	*  Describe other vaccine priority group variables  *
	*****************************************************
	
	foreach var of varlist smi neuro {
			safetab `var', m
	}	

			
	********************************
	*  Describe outcome variables  *
	********************************
		
	summ coviddeath_date otherdeath_date covidadmission_date composite_date, d format

	if `i'==1 {	
		safetab coviddeath1 
		safetab covidadmission1 
		safetab coviddeath1 covidadmission1
		safetab composite1
	}
	safetab coviddeath2 
	safetab covidadmission2 
	safetab coviddeath2 covidadmission2
	safetab composite2

	summ stime*

}

* Close log file
log close



