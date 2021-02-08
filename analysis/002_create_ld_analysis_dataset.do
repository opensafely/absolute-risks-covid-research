********************************************************************************
*
*	Do-file:		002_create_ld_analysis_dataset.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*						data_base_cohort1.dta 
*						data_base_cohort2.dta 
*
*	Data created:   analysis/
*							analysis/data_ldanalysis_cohort1.dta
*							analysis/data_ldanalysis_cohort2.dta
*
*	Other output:	Log file:  logs/002_create_ld_analysis_dataset.log
*
********************************************************************************
*
*	Purpose:		This do-file creates the variables required for the 
*					learning disability analysis and creates the survival
*					settings required for Stata to analyse.
*  
********************************************************************************




* Open a log file
cap log close
log using "logs/002_create_ld_analysis_dataset", replace t

* Wave 1: i=1  (1 Mar 20 - 31 Aug 20) 
* Wave 2: i=2  (1 Sept 20 - latest)
forvalues i = 1 (1) 2 {
	 
	* Open dataset
	if `i'<=1 {
		local j = 1
	}
	else {
		local j = 2
	}
	use "analysis/data_base_cohort`j'.dta", clear 


	* Index date
	if `i'<=1 {
		local index_date = "2020-03-01"
	}
	else if `i'==2 {
		local index_date = "2020-09-01"	    
	}
	
	* Display the input parameter (index date for cohort)
	noi di "`index_date'"
	local index = date(subinstr("`index_date'", "-", "/", .), "YMD")
	



	**************************
	*  Categorise variables  *
	**************************


	/*  Age variables  */ 

	* Create categorised age
	recode 	age 			 0/15.9999=1	///
							16/44.9999=2 	///
							45/64.9999=3 	///
							65/69.9999=4 	///
							70/74.9999=5 	///
							75/79.9999=6 	///
							80/max=7, 		///
							gen(agegroup) 

	label define agegroup 	1 "0-<16" 		///
							2 "16-<45" 		///
							3 "45-<65" 		///
							4 "65-<70" 		///
							5 "70-<75" 		///
							6 "75-<80" 		///
							6 "80+"
	label values agegroup agegroup


	* Check there are no missing ages
	assert agegroup<.


	*  Age splines 
			
	qui summ age
	mkspline age = age, cubic nknots(4)
	order age1 age2 age3, after(age)

	* Child indicator

	recode age min/15.999999=1 16/max=0, gen(child)



	/*  Body Mass Index  */

	* Only include child BMI measurements within 2 years
	replace bmi = . if age<16 & (`index' - bmi_child_date_measured_date) > 365.25*2
	drop bmi_child_date_measured_date

	recode bmi min/39.99999=0 40/max=1, gen(obese40)
	replace obese40 = 0 if bmi>=.
	order obese40, after(bmi)




	/*  IMD  */

	* Group into 5 groups
	assert imd_order!=-1
	egen imd = cut(imd_order), group(5) icodes
	replace imd = imd + 1
	replace imd = .u if imd_order>=.
	drop imd_order

	* Reverse the order (so high is more deprived)
	recode imd 5=1 4=2 3=3 2=4 1=5 .u=.u

	label define imd 	1 "1 least deprived"	///
						2 "2" 					///
						3 "3" 					///
						4 "4" 					///
						5 "5 most deprived" 	///
						.u "Unknown"
	label values imd imd 





	***************************
	*  Grouped comorbidities  *
	***************************


	/*  Spleen  */

	* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
	egen spleen_date = rowmin(dysplenia_date sickle_cell_date)
	format spleen_date %td
	order spleen_date spleen, after(sickle_cell)
	drop dysplenia_date sickle_cell_date



	/*  Non-haematological malignancies  */

	gen exhaem_cancer_date = min(lung_cancer_date, other_cancer_date)
	format exhaem_cancer_date %td
	order exhaem_cancer_date, after(other_cancer_date)
	drop lung_cancer_date other_cancer_date

	rename haem_cancer_date		cancerHaem_date
	rename exhaem_cancer_date	cancerExhaem_date

	* Only consider non-haematological malignancies if in previous year
	gen cancerExhaem1yr = inrange(cancerExhaem_date, `index'- 365.25, `index')
	drop cancerExhaem_date



	/*  Haematological malignancies  */

	gen     cancerHaem = 4 if 											///
				inrange(cancerHaem_date, d(1/1/1900), `index' - 5*365.25)
	replace cancerHaem = 3 if 											///
				inrange(cancerHaem_date, `index' - 5*365.25, `index' - 365.25)
	replace cancerHaem = 2 if											///
				inrange(cancerHaem_date, `index' - 365.25,   `index')
	recode  cancerHaem . = 1

	* Label cancer variables
	capture label drop cancer
	label define cancer 1 "Never" 			///
						2 "Last year" 		///
						3 "2-5 years ago" 	///
						4 "5+ years"
	label values cancerHaem	cancer
		

	/*  Immunosuppression  */

	* Temporary immunodeficiency or aplastic anaemia last year, HIV/permanent
	*   condition ever
	gen immunosuppression = 										 	  ///
			(inrange(temp_immuno_date,      `index' - 365.25, `index')	| ///
			 inrange(aplastic_anaemia_date, `index' - 365.25, `index')	| ///
			(perm_immuno_date < `index')								| ///
			(hiv_date < `index'))
	drop temp_immuno_date aplastic_anaemia_date perm_immuno_date hiv_date



	/*  Dialysis  */


	* If transplant since dialysis, set dialysis to no
	gen dialysis			= (dialysis_date <.)
	gen transplant_kidney 	= (transplant_kidney_date <.)
	replace dialysis = 0   if dialysis == 1				///
							& transplant_kidney	== 1  	///
							& transplant_kidney_date > dialysis_date 
	order dialysis, after(transplant_kidney_date)
	drop dialysis_date 




	/*  Transplant  */

	egen transplant_date = rowmin(transplant_kidney_date ///
								  transplant_notkidney_date)
	drop transplant_kidney_date transplant_notkidney_date
	format transplant_date %td







	**************************
	*  "Ever" comorbidities  *
	**************************

	* Replace dates with binary indicators 
	foreach var of varlist	respiratory_date	 			///
							cf_date	 						///
							cardiac_date 					///
							diabetes_date 					///
							af_date 						///
							dvt_pe_date						///
							tia_date						///
							stroke_date						///
							dementia_date		 			///
							neuro_date 						///
							liver_date 						///
							transplant_date 				///	
							spleen_date						///
							autoimmune_date 				///
							ibd_date 						///
							smi_date 						///
							ldr_date 						///
							ld_profound_date 				///
							ds_date 						///
							cp_date 						///
						{
		local newvar =  substr("`var'", 1, length("`var'") - 5)
		gen `newvar' = (`var'< `index')
		order `newvar', after(`var')
		drop `var'
	}






	 

	************
	*   eGFR   *
	************


	label define kidneyfn 	1 "None" 					///
							2 "Stage 3a/3b egfr 30-60"	///
							3 "Stage 4/5 egfr<30"
					
	* Categorise into CKD stages
	egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
	recode egfr_cat 0=5 15=4 30=3 45=2 60=0

	* Kidney function 
	recode egfr_cat 0=1 2/3=2 4/5=3, gen(kidneyfn)
	replace kidneyfn = 1 if egfr==. 
	label values kidneyfn kidneyfn 

	* Delete variables no longer needed
	drop egfr egfr_cat

	* If either dialysis or kidney transplant then set kidney function to the 
	*   lowest level
	replace  kidneyfn = 3 if dialysis			== 1
	replace  kidneyfn = 3 if transplant_kidney	== 1
	drop transplant_kidney



	****************************************
	*   Hba1c:  Level of diabetic control  *
	****************************************

	label define hba1ccat	0 "<6.5%"  		///
							1">=6.5-7.4"  	///
							2">=7.5-7.9" 	///
							3">=8-8.9" 		///
							4">=9"



	/* Categorise hba1c and diabetes  */

	* Group hba1c
	gen 	hba1ccat = 0 if hba1c_pct <  6.5
	replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
	replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
	replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
	replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
	label values hba1ccat hba1ccat

	* Delete unneeded variables
	drop hba1c_pct 

	* Create diabetes, split by control/not
	gen     diabcat = 1 if diabetes==0
	replace diabcat = 2 if diabetes==1 & inlist(hba1ccat, 0, 1)
	replace diabcat = 3 if diabetes==1 & inlist(hba1ccat, 2, 3, 4)
	replace diabcat = 4 if diabetes==1 & !inlist(hba1ccat, 0, 1, 2, 3, 4)

	label define diabetes 	1 "No diabetes" 			///
							2 "Controlled diabetes"		///
							3 "Uncontrolled diabetes" 	///
							4 "Diabetes, no hba1c measure"
	label values diabcat diabetes




	************************************
	*  Exposures: learning disability  *
	************************************

	* Split LDR into moderate-mild and severe-profound
	noi tab ldr ld_profound, m

	gen ldr_cat = ldr
	recode ldr_cat 1=2 if ld_profound==1

	label define ldprofound 0 "Not on LDR"	///
							1 "LDR, mild"	///
							2 "LDR, profound"
	label values ldr_cat ldprofound


	* Split into in residential care and not
	noi tab ldr resid_care_ld, m

	gen ldr_carecat = ldr
	recode ldr 1=2 if resid_care_ld==1

	label define ldcare 0 "Not on LDR"							///
							1 "LDR, not in residential care"	///
							2 "LDR, in residential care"
	label values ldr_carecat ldcare





	***************************************
	*  Binary outcomes and survival time  *
	***************************************

	* Check all dates are in future
	assert coviddeath_date 		>= `index'
	assert otherdeath_date 		>= `index'
	assert covidadmission_date 	>= `index'



	*** WAVE 1 CENSORING *** 31st August 2020
	global coviddeathcensor1     = d(31Aug2020)
	global covidadmissioncensor1 = d(31Aug2020)

	*** WAVE 2 CENSORING *** last outcome date minus 7 days
	* COVID death
	noi summ coviddeath_date, format
	global coviddeathcensor2 = r(max) - 7
		
	* COVID hospital admission
	noi summ covidadmission_date, format
	global covidadmissioncensor2 = r(max) - 7


	gen coviddeathcensor1     = $coviddeathcensor1
	gen covidadmissioncensor1 = $covidadmissioncensor1

	gen coviddeathcensor2     = $coviddeathcensor2
	gen covidadmissioncensor2 = $covidadmissioncensor2

		
	* Composite outcome date (either COVID-19 death or hospitalisation)
	gen composite_date = min(coviddeath_date, covidadmission_date)
		

	/*  Binary outcome and survival time  */

	forvalues k = 1 (1) 2 {
	    
		* COVID-19 death
		gen 	coviddeath`k' = (coviddeath_date<.)
		replace coviddeath`k' = 0 if coviddeath_date > coviddeathcensor`k'
		replace coviddeath`k' = 0 if coviddeath_date > otherdeath_date

		* COVID-19 hospitalisation
		gen 	covidadmission`k' = (covidadmission_date<.)
		replace covidadmission`k' = 0 if covidadmission_date > covidadmissioncensor`k'
		replace covidadmission`k' = 0 if covidadmission_date > coviddeathcensor`k'
		replace covidadmission`k' = 0 if covidadmission_date > coviddeath_date
		replace covidadmission`k' = 0 if covidadmission_date > otherdeath_date

		* Composite (either COVID-19 death or hospitalisation)
		gen 	composite`k' = (composite_date<.)
		replace composite`k' = 0 if composite_date > covidadmissioncensor`k'
		replace composite`k' = 0 if composite_date > coviddeathcensor`k'
		format composite_date %td


		/*  Calculate survival times  (days until event/censoring)  */

		egen stime_coviddeath`k' 	 = rowmin(coviddeath_date    	/// 
									otherdeath_date 				///
									coviddeathcensor`k') 
		egen stime_covidadmission`k' = rowmin(covidadmission_date 	///
									coviddeath_date 				///
									otherdeath_date					/// 
									covidadmissioncensor`k' 		///
									coviddeathcensor`k')
		egen stime_composite`k'      = rowmin(composite_date 		///
									otherdeath_date					/// 
									covidadmissioncensor`k' 		///
									coviddeathcensor`k')

		* Convert to days since index date
		foreach var of varlist stime* {
			replace `var' = `var' - `index' + 1
		}
		drop coviddeathcensor`k' covidadmissioncensor`k' 
	}
	
	
	
	* Wave 1: Keep both outcomes (censored at Aug 31, and all time)
	* Wave 2: Keep only outcome censored at end
	if `i'==2 {
	    drop coviddeath1 covidadmission1 composite1 ///
			stime_coviddeath1 stime_covidadmission1 stime_composite1
	}

	
	

	*********************
	*  Label variables  *
	*********************


	* Demographics
	label var patient_id			"Patient ID"
	label var age 					"Age (years)"
	label var age1 					"Age spline term 1"
	label var age2 					"Age spline term 2"
	label var age3 					"Age spline term 3"
	label var agegroup				"Grouped age"
	label var male 					"Male"
	label var imd 					"Index of Multiple Deprivation (IMD)"
	label var ethnicity_5			"Ethnicity in 16 categories"
	label var stp 					"Sustainability and Transformation Partnership"
	label var stpcode 				"Sustainability and Transformation Partnership"
	label var region_7 				"Geographical region (7 England regions)"
	label var household_id			"Household ID"
	label var resid_care_old 		"Residential care, elderly"
	label var resid_care_ldr 		"Residential care, learning disability"


	* Learning disabilities
	label var ldr 					"Learning disability or Down's Syndrome"
	label var ld_profound 			"Severe-profound learning disability or Down's Syndrome"
	label var ldr_cat				"Learning disability split into mild-moderate and severe-profound" 
	label var ldr_carecat			"Learning disability split into residential vs non-residential setting" 
	label var ds 					"Down's Syndrome"
	label var cp 					"Cerebral Palsy"


	* Confounders and comorbidities 
	label var bmi					"Body Mass Index (BMI, kg/m2)"
	label var obese40				"Evidence of BMI>40"
	label var asthmacat				"Severity of asthma"
	label var respiratory 			"Respiratory disease (excl. asthma)"
	label var cardiac				"Heart disease"
	label var af					"Atrial fibrillation"
	label var dvt					"Deep vein thrombosis/pulmonary embolism"
	label var diabcat				"Diabetes"
	label var tia					"Transient ischemic attack"
	label var stroke				"Stroke"
	label var dementia				"Dementia"
	label var neuro					"Neuro condition other than stroke/dementia"	
	label var cancerExhaem1yr		"Non haematological cancer"
	label var cancerHaem			"Haematological cancer"
	label var liver					"Liver disease"
	label var kidneyfn				"Kidney function"
	label var transplant			"Organ transplant recipient"
	label var spleen				"Spleen problems (dysplenia, sickle cell)"
	label var autoimmune			"RA, SLE, Psoriasis (autoimmune disease)"
	label var immunosuppression		"Conditions causing permanent or temporary immunosuppression"
	label var ibd					"IBD"
	label var smi 					"Serious mental illness"

	* Outcomes 
	label var  coviddeath_date			"Date of ONS COVID-19 death"
	label var  otherdeath_date 			"Date of ONS non-COVID-19 death"
	label var  covidadmission_date		"Date of COVID-19 hospital admission"
	label var  composite_date			"Date of first of COVID-19 hospital admission or death"
			
	local tag1 = "censored 31 Aug 20"
	local tag2 = "censored latest date"
	
	forvalues k = 1 (1) 2 {
		capture label var  coviddeath`k'			"COVID-19 death (ONS), `tag`k''"
		capture label var  covidadmission`k'		"COVID-19 hospital admission, `tag`k''"
		capture label var  composite`k'				"COVID-19 hospital admission or death, `tag`k''"
			
		capture label var  stime_coviddeath`k'		"Days from study entry until COVID-19 death or censoring, `tag`k''"
		capture label var  stime_covidadmission`k'	"Days from study entry until COVID-19 hospital admission or censoring, `tag`k''"
		capture label var  stime_composite`k'		"Days from study entry until COVID-19 hospital admission or death or censoring, `tag`k''"
	}	


	*********************
	*  Order variables  *
	*********************

	sort patient_id
	order 	patient_id stp* region_7 imd rural 					 		///
			household* resid_care_old resid_care_ldr			 		///
			ldr ldr_cat ld_profound ldr_carecat ds cp					///
			age age age1 age2 age3 agegroup child male					///
			bmi* obese* ethnicity*										/// 
			respiratory* asthma* cf* cardiac* diabcat*	 				///
			af* dvt_pe* 												///
			stroke* dementia* neuro* tia*								///
			cancerExhaem* cancerHaem* 									///
			kidneyfn* dialysis* liver* transplant* 						///
			spleen* autoimmune* immunosuppression*	ibd*				///
			smi* 														///
			coviddeath* otherdeath* covidadmission* composite*

	keep 	patient_id stp* region_7 imd rural 					 		///
			household* resid_care_old resid_care_ldr			 		///
			ldr ldr_cat ld_profound ldr_carecat ds cp					///
			age age age1 age2 age3 agegroup child male					///
			bmi* obese* ethnicity*										/// 
			respiratory* asthmacat cf cardiac diabcat	 				///
			af dvt_pe stroke dementia neuro tia							///
			cancerExhaem* cancerHaem 									///
			kidneyfn dialysis liver transplant 							///
			spleen autoimmune immunosuppression ibd						///
			smi 														///
			coviddeath* otherdeath* covidadmission* composite*


			

	***************
	*  Save data  *
	***************

    sort patient_id
	if `i'==1 {
	    label data "Analysis dataset, wave 1 (1 Mar - 31 Aug 20), for learning disability work"
	}
	else if `i'==2 {
	    label data "Analysis dataset, wave 2 (1 Sept 20 - latest), for learning disability work"
	}
	* Save overall dataset
	save "analysis/data_ldanalysis_cohort`j'.dta", replace 
}

log close

