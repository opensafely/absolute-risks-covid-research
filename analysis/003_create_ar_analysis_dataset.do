********************************************************************************
*
*	Do-file:		003_create_absolute_risks_analysis_dataset.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*						data_base_cohort1.dta 
*						data_base_cohort2.dta 
*
*	Data created:   analysis/
*							data_aranalysis_cohort1.dta
*							data_aranalysis_cohort2.dta
*
*	Other output:	Log file:  logs/003_create_ar_analysis_dataset.log
*
********************************************************************************
*
*	Purpose:		This do-file creates the variables required for the 
*					absolute risks analysis and creates the survival
*					variables required for Stata to analyse.
*  
********************************************************************************




clear all
set more off

* Open a log file
cap log close
log using "logs/003_create_ar_analysis_dataset", replace t

* Wave 1: i=1  (1 Mar 20 - 31 Aug 20) 
* Wave 2: i=2  (1 Sept 20 - 3 March 21)
forvalues i = 1 (1) 2 {

	* Open data
	use "analysis/data_base_cohort`i'.dta", clear 

	* Index date
	if `i'==1 {
		local index_date = "2020-03-01"
	}
	else if `i'==2 {
		local index_date = "2020-09-01"	    
	}
	
	* Display the input parameter (index date for cohort)
	noi di "`index_date'"
	local index = date(subinstr("`index_date'", "-", "/", .), "YMD")
	noi di `index'


	****************
	*  Exclusions  *
	****************

	* Drop children
	drop if age < 18
	
	* Drop people with HIV
	drop if hiv_date<.
	drop hiv_date
	

	
	
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
							7 "80+"
	label values agegroup agegroup

	* Check there are no missing ages
	assert agegroup<.
	
	*  Age splines 		
	qui summ age
	mkspline age = age, cubic nknots(4)
	order age1 age2 age3, after(age)


	/*  Body Mass Index  */

	* Recode implausible BMI values
	replace bmi = . if !inrange(bmi, 15, 50)
	drop bmi_child_date_measured_date
	
	* Labels for BMI variables
	label define bmicat 	1 "Underweight (<18.5)" 				///
							2 "Normal (18.5-24.9)"					///
							3 "Overweight (25-29.9)"				///
							4 "Obese I (30-34.9)"					///
							5 "Obese II (35-39.9)"					///
							6 "Obese III (40+)"						///
							.u "Unknown (.u)"

	label define obesecat 	1 "Underweight (<18.5)" 				///
							2 "No record of obesity/underweight" 	///
							3 "Obese I (30-34.9)"					///
							4 "Obese II (35-39.9)"					///
							5 "Obese III (40+)"	

	* Categorised BMI (NB: watch for missingness)
    gen 	bmicat = .
	recode  bmicat . = 1 if bmi<18.5
	recode  bmicat . = 2 if bmi<25
	recode  bmicat . = 3 if bmi<30
	recode  bmicat . = 4 if bmi<35
	recode  bmicat . = 5 if bmi<40
	recode  bmicat . = 6 if bmi<.
	replace bmicat = .u  if bmi>=.
	label values bmicat bmicat
	
	* Create more granular categorisation
	recode bmicat 1=1 2/3 .u = 2 4=3 5=4 6=5, gen(obesecat)
	label values obesecat obesecat

	order obesecat bmicat, after(bmi)

		
		

	/*  Smoking  */

	* Create non-missing 3-category variable for current smoking
	recode smoke .u=1, gen(smoke_nomiss)
	order smoke_nomiss, after(smoke)
	label values smoke_nomiss smoke

	
	
	/*  Blood pressure   */

	* Categorise
	gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
	replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
	replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
	replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
	replace bpcat = .u if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

	label define bpcat 	1 "Normal" 			///
						2 "Elevated" 		///
						3 "High, stage I"	///
						4 "High, stage II" 	///
						.u "Unknown"
	label values bpcat bpcat

	recode bpcat .u=1, gen(bpcat_nomiss)
	label values bpcat_nomiss bpcat






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



	/*  Cancer  */
	
	* Combine non-haematological malignancies  
	gen exhaem_cancer_date = min(lung_cancer_date, other_cancer_date)
	format exhaem_cancer_date %td
	order exhaem_cancer_date, after(other_cancer_date)
	drop lung_cancer_date other_cancer_date

	rename haem_cancer_date		cancerHaem_date
	rename exhaem_cancer_date	cancerExhaem_date

	*  Group non-haematological malignancies by diagnosis date 
	gen     cancerExhaem = 4 if 											///
				inrange(cancerExhaem_date, d(1/1/1900), `index' - 5*365.25)
	replace cancerExhaem = 3 if 											///
				inrange(cancerExhaem_date, `index' - 5*365.25, `index' - 365.25)
	replace cancerExhaem = 2 if												///
				inrange(cancerExhaem_date, `index' - 365.25,   `index')
	recode  cancerExhaem . = 1

	*  Group haematological malignancies by diagnosis date 
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
	label values cancerExhaem	cancer
	label values cancerHaem	 	cancer
		
		

	/*  Immunosuppression  */

	* Temporary immunodeficiency or aplastic anaemia last year, HIV/permanent
	*   condition ever
	gen immunosuppression = 										 	  ///
			(inrange(temp_immuno_date,      `index' - 365.25, `index')	| ///
			 inrange(aplastic_anaemia_date, `index' - 365.25, `index')	| ///
			(perm_immuno_date < `index'))
	drop temp_immuno_date aplastic_anaemia_date perm_immuno_date 



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




	/*  Fracture  */

	gen fracture = (fracture_date<.)
	drop fracture_date

	* Ignore fractures for people aged < 65
	replace fracture = 0 if age<65



	/*  Peripheral arterial disease  */

	* First of either surgery for PAD or limb amputation
	egen pad_date = rowmin(pad_surg_date amputate_date)
	drop pad_surg_date amputate_date
	format pad_date %td






	**************************
	*  "Ever" comorbidities  *
	**************************

	* Replace dates with binary indicators 
	foreach var of varlist	respiratory_date	 			///
							cf_date	 						///
							cardiac_date 					///
							diabetes_date 					///
							hypertension_date				///
							af_date 						///
							dvt_pe_date						///
							pad_date						///
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
							ds_date 						///
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
	drop egfr_cat

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

	* Delete unneeded variables
	drop hba1ccat 

	

	***************************************
	*  Binary outcomes and survival time  *
	***************************************

	* Summarise data
	noi summ coviddeath_date covidadmission_date, format

	*** WAVE 1 CENSORING *** 31st August 2020
	global coviddeathcensor1     = d(31Aug2020)
	global covidadmissioncensor1 = d(31Aug2020)

	*** WAVE 2 CENSORING *** 3 March 2021 (same duration)
	global coviddeathcensor2     = d(3Mar2021)
	global covidadmissioncensor2 = d(3Mar2021)
	

	gen coviddeathcensor1     = $coviddeathcensor1
	gen covidadmissioncensor1 = $covidadmissioncensor1

	gen coviddeathcensor2     = $coviddeathcensor2
	gen covidadmissioncensor2 = $covidadmissioncensor2

			

	* Composite outcome date (either COVID-19 death or hospitalisation)
	egen composite_date = rowmin(coviddeath_date covidadmission_date)
		

	/*  Binary outcome and survival time  */

	* Events prior to index date (shouldn't happen in real data)
	noi count if otherdeath_date     < `index'
	noi count if coviddeath_date     < `index'
	noi count if covidadmission_date < `index'
		
	forvalues k = 1 (1) 2 {

		/*  Censoring for competing events  */
		
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

		* Non-COVID-19 death
		gen 	noncoviddeath`k' = (otherdeath_date<.)
		replace noncoviddeath`k' = 0 if otherdeath_date > coviddeathcensor`k'
		replace noncoviddeath`k' = 0 if otherdeath_date > coviddeath_date

		
		/*  Not censoring for competing events  */
		
		* COVID-19 death
		gen 	coviddeath`k'_nocensor = (coviddeath_date<.)
		replace coviddeath`k'_nocensor = 0 if coviddeath_date > coviddeathcensor`k'

		* COVID-19 hospitalisation
		gen 	covidadmission`k'_nocensor = (covidadmission_date<.)
		replace covidadmission`k'_nocensor = 0 if covidadmission_date > covidadmissioncensor`k'
		replace covidadmission`k'_nocensor = 0 if covidadmission_date > coviddeathcensor`k'

		
		
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
		egen stime_noncoviddeath`k' = rowmin(otherdeath_date    	/// 
									coviddeath_date 				///
									coviddeathcensor`k') 
									
		egen stime_coviddeath`k'_nocensor							///
									= rowmin(coviddeath_date    	/// 
									coviddeathcensor`k') 
		egen stime_covidadmission`k'_nocensor						///
								= rowmin(covidadmission_date 		///
									covidadmissioncensor`k' 		///
									coviddeathcensor`k')
									
		drop coviddeathcensor`k' covidadmissioncensor`k' 
	}
	
	* Convert to days since index date
	foreach var of varlist stime* {
		replace `var' = `var' - `index' + 1
	}	
	
	* Wave 1: Keep both outcomes (censored at Aug 31, and all time)
	* Wave 2: Keep only outcome censored at end
	if `i'==2 {
	    drop 	coviddeath1 stime_coviddeath1							///
				covidadmission1 stime_covidadmission1					///
				composite1 stime_composite1 							///
				noncoviddeath1 stime_noncoviddeath1						///
				coviddeath1_nocensor stime_coviddeath1_nocensor			///
				covidadmission1_nocensor stime_covidadmission1_nocensor	
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
	label var smoke 				"Smoking status (with missingness)"
	label var smoke_nomiss 			"Smoking status (no missingness)"
	label var ethnicity_5			"Ethnicity in 5 categories"
	label var stp 					"Sustainability and Transformation Partnership"
	label var stpcode 				"Sustainability and Transformation Partnership"
	label var region_7 				"Geographical region (7 England regions)"
	label var household_id			"Household ID"
	label var resid_care_old 		"Residential care, elderly"


	* Confounders and comorbidities 
	label var bpcat 				"Blood pressure category (with missingness)"
	label var bpcat_nomiss 			"Blood pressure category (no missingness)"
	label var hypertension 			"Diagnosed hypertension"
	label var bmi					"Body Mass Index (BMI, kg/m2)"
	label var bmicat				"BMI group (missing data)"
	label var obesecat				"Obesity group (no missing)"
	label var asthmacat				"Asthma"
	label var respiratory 			"Respiratory disease (excl. asthma)"
	label var cardiac				"Heart disease"
	label var cf					"Cystic Fibrosis (& related)"
	label var af					"Atrial fibrillation"
	label var dvt					"Deep vein thrombosis/pulmonary embolism"
	label var pad					"Surgery for arterial disease"
	label var diabcat				"Diabetes"
	label var hba1c					"Hba1c"
	label var tia					"Transient ischemic attack"
	label var stroke				"Stroke"
	label var dementia				"Dementia"
	label var neuro					"Neuro condition other than stroke/dementia"	
	label var cancerExhaem			"Non haematological cancer"
	label var cancerHaem			"Haematological cancer"
	label var liver					"Liver disease"
	label var kidneyfn				"Kidney function"
	label var egfr					"Estimated GFR"
	label var transplant			"Organ transplant recipient"
	label var dialysis				"Dialysis"
	label var spleen				"Spleen problems (dysplenia, sickle cell)"
	label var autoimmune			"RA, SLE, Psoriasis (autoimmune disease)"
	label var immunosuppression		"Conditions causing permanent or temporary immunosuppression"
	label var ibd					"IBD"
	label var smi 					"Serious mental illness"
	label var ds 					"Down's Syndrome"
	label var ldr 					"On learning disability register"
	label var fracture 				"Fracture (in 65+)"

	* Outcomes 
	label var  coviddeath_date			"Date of ONS COVID-19 death"
	label var  otherdeath_date 			"Date of ONS non-COVID-19 death"
	label var  covidadmission_date		"Date of COVID-19 hospital admission"
	label var  composite_date			"Date of first of COVID-19 hospital admission or death"
			
	local tag1 = "censored 31 Aug 20"
	local tag2 = "censored latest date"
	
	forvalues k = 1 (1) 2 {
		capture label var  coviddeath`k'				"COVID-19 death (ONS), `tag`k''"
		capture label var  covidadmission`k'			"COVID-19 hospital admission, `tag`k''"
		capture label var  composite`k'					"COVID-19 hospital admission or death, `tag`k''"
		capture label var  noncoviddeath`k'				"Non COVID-19 death (ONS), `tag`k''"

		capture label var  coviddeath`k'_nocensor		"COVID-19 death (ONS) (competing events not censored), `tag`k''"
		capture label var  covidadmission`k'_nocensor	"COVID-19 hospital admission  (competing events not censored), `tag`k''"

		capture label var  stime_coviddeath`k'				///
			"Days from study entry until COVID-19 death or censoring, `tag`k''"
		capture label var  stime_covidadmission`k'			///
			"Days from study entry until COVID-19 hospital admission or censoring, `tag`k''"
		capture label var  stime_composite`k'				///
			"Days from study entry until COVID-19 hospital admission or death or censoring, `tag`k''"
		capture label var  stime_noncoviddeath`k'			///
			"Days from study entry until Non-COVID-19 death or censoring, `tag`k''"
		
		capture label var  stime_coviddeath`k'_nocensor		///
			"Days from study entry until COVID-19 death or censoring (competing events not censored), `tag`k''"
		capture label var  stime_covidadmission`k'_nocensor	///
			"Days from study entry until COVID-19 hospital admission or censoring (competing events not censored), `tag`k''"
	}	


	*********************
	*  Order variables  *
	*********************

	sort patient_id
	order 	patient_id stp* region_7 rural imd 					 		///
			household* resid_care_old smoke*					 		///
			age age age1 age2 age3 agegroup male						///
			bmi* obese* ethnicity*										/// 
			respiratory* asthma* cf* cardiac* diabcat* hba1c			///
			bpcat* hypertension* af* dvt_pe* pad*						///
			stroke* dementia* tia* neuro								///
			cancerExhaem cancerHaem 									///
			kidneyfn* egfr liver* transplant* dialysis					///
			spleen* autoimmune* immunosuppression*	ibd*				///
			smi ldr ds fracture*										///
			coviddeath* otherdeath* covidadmission* composite* 			///
			noncovid* stime*

	keep 	patient_id stp* region_7 rural imd 					 		///
			household* resid_care_old smoke*					 		///
			age age age1 age2 age3 agegroup male						///
			bmi* obese* ethnicity*										/// 
			respiratory asthma cf cardiac diabcat hba1c	 				///
			bpcat* hypertension af dvt_pe pad							///
			stroke dementia tia	neuro									///
			cancerExhaem cancerHaem 									///
			kidneyfn egfr liver transplant dialysis						///
			spleen autoimmune immunosuppression	ibd						///
			ldr ds smi fracture											///
			coviddeath* otherdeath* covidadmission* composite* 			///
			noncovid* stime*




	***************
	*  Save data  *
	***************

    sort patient_id
	if `i'==1 {
	    label data "Analysis dataset, wave 1 (1 Mar - 31 Aug 20), for absolute risk work"
	}
	else if `i'==2 {
	    label data "Analysis dataset, wave 2 (1 Sept 20 - latest), for absolute risk work"
	}
	* Save overall dataset
	save "analysis/data_aranalysis_cohort`i'.dta", replace 
}

log close




