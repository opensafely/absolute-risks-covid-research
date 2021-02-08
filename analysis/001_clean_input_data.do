********************************************************************************
*
*	Do-file:		001_clean_input_data.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		Data in memory (from input_`t'.csv), 
*							with t=2020-03-01 (wave 1) or t=2020-09-01 (wave 2)
*
*	Data created:   analysis/
*						data_base_cohort1.dta 
*						data_base_cohort2.dta 
*					(full base cohort dataset, waves 1 and 2)
*
*	Other output:	Log file:  logs/001_clean_input_data.log
*
********************************************************************************
*
*	Purpose:		This do-file reads in the input data, tidies and 
*					saves them into Stata datasets.
*  
********************************************************************************


* Open a log file
cap log close
log using "logs/001_clean_input_data", replace t


forvalues i = 1 (1) 2 {

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
	
	* Import data
	import delimited output/input_`index_date'.csv, clear


	****************************************
	*  Create residential care indicators  *
	****************************************
	
	* Households with 5+ over 65 and 5+ on learning disability register
	gen tempold = (age>=65)
	replace tempold = . if age>=.
	gen templdr  = (ldr != "")
	
	bysort household_id: egen num_old = sum(tempold)
	bysort household_id: egen num_ldr = sum(templdr)
	
	recode num_old 0/4=0 5/max=1, gen(resid_care_old)
	recode num_ldr 0/4=0 5/max=1, gen(resid_care_ldr)
	drop templdr tempold num_old num_ldr
	
	order resid_care_old resid_care_ldr, after(household_id)
	
	
	
	****************************
	*  Create required cohort  *
	****************************

	di "STARTING COUNT FROM IMPORT:"
	noi count

	* Age: Exclude implausibly ages (below zero and above 105)
	qui summ age // Should be no missing ages
	noi di "DROPPING AGE>105:" 
	drop if age>105
	noi di "DROPPING AGE<0:" 
	drop if age<0
	assert inrange(age, 0, 105)

	* Sex: Exclude categories other than M and F
	assert inlist(sex, "M", "F", "I", "U")
	noi di "DROPPING GENDER NOT M/F:" 
	drop if inlist(sex, "I", "U")

	* Sustainability and Transformation Partnership (geographic area):
	*   Exclude if missing
	noi di "DROPPING IF STP MISSING:"
	drop if stp==""

	* Index of Multiple Deprivation: Exclude if missing 
	noi di "DROPPING IF NO IMD" 
	capture confirm string var imd 
	if _rc==0 {
		drop if imd==""
	}
	else {
		drop if imd>=.
		drop if imd==-1
	}


	* People who had an event prior to our start date
	* (this should not occur in the real data)
	noi di "DROPPING IF DIED BEFORE INDEX DATE" 
	confirm string variable died_date_ons
	gen temp = date(died_date_ons, "YMD")
	drop if temp < `index'
	drop temp




	***********************************************
	*  Convert strings to dates (for covariates)  *
	***********************************************

	foreach var of varlist 	cf								///
							respiratory					 	///
							cardiac 						///
							hypertension 					///
							af 								///
							dvt_pe							///
							pad_surg 						///
							amputate						///
							diabetes 						///
							tia								///
							stroke							///
							dementia		 				///
							neuro 							///
							lung_cancer 					///
							haem_cancer						///
							other_cancer 					///
							liver				 			///
							transplant_notkidney 			///	
							transplant_kidney				///
							dialysis						///
							dysplenia						///
							sickle_cell 					///
							hiv 							///
							perm_immuno				 		///
							aplastic_anaemia				///
							temp_immuno						///
							autoimmune		  				///
							ibd 							///
							fracture						///
							smi 							///
							ldr								///
							ld_profound 					///
							ds 								///
							cp								///
							{
		capture confirm string variable `var'
		if _rc!=0 {
			assert `var'==.
			rename `var' `var'_date
		}
		else {
			replace `var' = `var' + "-15"
			rename `var' `var'_dstr
			replace `var'_dstr = " " if `var'_dstr == "-15"
			gen `var'_date = date(`var'_dstr, "YMD") 
			order `var'_date, after(`var'_dstr)
			drop `var'_dstr
		}
		format `var'_date %td
	}






	**********************
	*  Recode variables  *
	**********************


	/*  Demographics  */

	* Check there are no missing ages
	assert age<.

	* Sex
	assert inlist(sex, "M", "F")
	gen male = (sex=="M")
	drop sex


	* Smoking
	label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"

	gen     smoke = 1  if smoking_status=="N"
	replace smoke = 2  if smoking_status=="E"
	replace smoke = 3  if smoking_status=="S"
	replace smoke = .u if smoking_status=="M"
	replace smoke = .u if smoking_status==""
	label values smoke smoke
	drop smoking_status 



	* Ethnicity (5 category)
	rename ethnicity ethnicity_5
	replace ethnicity_5 = .u if ethnicity_5==.
	label define ethnicity 	1 "White"  								///
							2 "Mixed" 								///
							3 "Asian or Asian British"				///
							4 "Black"  								///
							5 "Other"								///
							.u "Unknown"
	label values ethnicity_5 ethnicity

	* Ethnicity (16 category)
	replace ethnicity_16 = .u if ethnicity_5>=.
	replace ethnicity_16 = .u if ethnicity_16>=.
	label define ethnicity_16 										///
							1 "British or Mixed British" 			///
							2 "Irish" 								///
							3 "Other White" 						///
							4 "White + Black Caribbean" 			///
							5 "White + Black African"				///
							6 "White + Asian" 						///
							7 "Other mixed" 						///
							8 "Indian or British Indian" 			///
							9 "Pakistani or British Pakistani" 		///
							10 "Bangladeshi or British Bangladeshi" ///
							11 "Other Asian" 						///
							12 "Caribbean" 							///
							13 "African" 							///
							14 "Other Black" 						///
							15 "Chinese" 							///
							16 "Other" 								///
							.u "Unknown"  
	label values ethnicity_16 ethnicity_16
	drop ethnicity_date ethnicity_16_date



	/* BMI */


	* For adults
	replace bmi_adult = . if age<16

	* For children	
	capture confirm string variable bmi_child_date_measured
	if _rc!=0 {
		assert bmi_child_date_measured==.
		rename bmi_child_date_measured bmi_child_date_measured_date
	}
	else {
		replace bmi_child_date_measured = bmi_child_date_measured + "-15"
		rename bmi_child_date_measured bmi_child_date_measured_dstr
		replace bmi_child_date_measured_dstr = " " if bmi_child_date_measured_dstr == "-15"
		gen bmi_child_date_measured_date = date(bmi_child_date_measured_dstr, "YMD") 
		order bmi_child_date_measured_date, after(bmi_child_date_measured_dstr)
		drop bmi_child_date_measured_dstr
	}
	format bmi_child_date_measured_date %td
	replace bmi_child 					 = . if age>=16
	replace bmi_child_date_measured_date = . if age>=16

	* Combine BMI measurements
	noi summ bmi_adult bmi_child 
	gen     bmi = bmi_adult if age>=16
	replace bmi = bmi_child if age<16
	replace bmi = . if !inrange(bmi, 15, 50)
	order bmi, after(bmi_adult)
	drop bmi_adult bmi_child



	/*  Geographical location  */


	* STP 
	rename stp stpcode
	bysort stpcode: gen stp = 1 if _n==1
	replace stp = sum(stp)
	order stp, after(stpcode)

	* Region
	gen     region_7 = 1 if region=="East"
	replace region_7 = 2 if region=="London"
	replace region_7 = 3 if region=="East Midlands" 
	replace region_7 = 3 if region=="West Midlands"
	replace region_7 = 4 if region=="North East" 
	replace region_7 = 4 if region=="Yorkshire and The Humber"
	replace region_7 = 5 if region=="North West"
	replace region_7 = 6 if region=="South East"
	replace region_7 = 7 if region=="South West"

	label define region_7 	1 "East"							///
							2 "London" 							///
							3 "Midlands"						///
							4 "North East and Yorkshire"		///
							5 "North West"						///
							6 "South East"						///	
							7 "South West"
	label values region_7 region_7
	label var region_7 "Region of England (7 regions)"
	drop region


	*  Rural-urban classification 
	capture confirm string var rural_urban 
	if _rc==0 {
		assert inlist(rural_urban, "rural", "urban", "")
		replace rural_urban = "urban" if !inlist(rural_urban, "rural", "urban")

		gen rural = rural_urban=="rural"
		order rural, after(rural_urban)
		drop rural_urban
	}
	else {
		recode rural_urban -1 0=.
		bysort stp: egen ru_mode=mode(rural_urban)
		replace rural_urban = ru_mode if rural_urban>=.
		drop ru_mode
		
		* Categorise
		recode rural_urban 1/4=0 5/8=1, gen(rural)
		order rural, after(rural_urban)
		drop rural_urban
	}


	*  IMD 
	rename imd imd_order




	/*  Asthma  */

	label define asthmacat	1 "No" 				///
							2 "Yes, no OCS" 	///
							3 "Yes with OCS"

	* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
	rename asthma_severity asthmacat
	recode asthmacat 0=1 1=2 2=3
	label values asthmacat asthmacat




	************
	*   eGFR   *
	************

	* Set implausible creatinine values to missing (Note: zero changed to missing)
	replace creatinine = . if !inrange(creatinine, 20, 3000) 

	* Divide by 88.4 (to convert umol/l to mg/dl)
	gen SCr_adj = creatinine/88.4

	gen 	min = .
	replace min = SCr_adj/0.7 	if male==0
	replace min = SCr_adj/0.9 	if male==1
	replace min = min^-0.329  	if male==0
	replace min = min^-0.411  	if male==1
	replace min = 1 			if min<1

	gen 	max = .
	replace max = SCr_adj/0.7 	if male==0
	replace max = SCr_adj/0.9 	if male==1
	replace max = max^-1.209
	replace max = 1 			if max>1

	gen 	egfr = min*max*141
	replace egfr = egfr*(0.993^age)
	replace egfr = egfr*1.018 if male==0

	replace egfr = . if creatinine==. 

	* Delete variables no longer needed
	drop min max SCr_adj creatinine 


	 
		
	****************************************
	*   Hba1c:  Level of diabetic control  *
	****************************************

	* Set zero or negative to missing
	replace hba1c_percentage   = . if hba1c_percentage   <= 0
	replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0


	/* Express  HbA1c as percentage  */ 

	* Express all values as perecentage 
	noi summ hba1c_percentage hba1c_mmol_per_mol
	gen 	hba1c_pct = hba1c_percentage 
	replace hba1c_pct = (hba1c_mmol_per_mol/10.929) + 2.15  ///
				if hba1c_mmol_per_mol<. 

	* Valid % range between 0-20  
	replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
	replace hba1c_pct = round(hba1c_pct, 0.1)


	* Delete unneeded variables
	drop hba1c_percentage hba1c_mmol_per_mol 




	********************************
	*  Outcomes and survival time  *
	********************************


	/*   Outcomes   */

	* Format ONS death date
	confirm string variable died_date_ons
	rename died_date_ons died_date_ons_dstr
	gen died_date_ons = date(died_date_ons_dstr, "YMD")
	format died_date_ons %td
	drop died_date_ons_dstr

	* Date of Covid death in ONS
	gen coviddeath_date = died_date_ons if died_ons_covid_flag_any==1
	gen otherdeath_date = died_date_ons if died_ons_covid_flag_any!=1
	drop died_date_ons
	format coviddeath_date otherdeath_date %td

	* Delete unneeded variables
	drop died_ons_covid_flag_any 

	* COVID-19 admission
	confirm string variable covid_admission_date
	rename covid_admission_date covid_admission_date_dstr
	gen covidadmission_date = date(covid_admission_date_dstr, "YMD")
	format covidadmission_date %td
	drop covid_admission_date_dstr


	*********************
	*  Label variables  *
	*********************


	* Demographics
	label var patient_id				"Patient ID"
	label var age 						"Age (years)"
	label var male 						"Male"
	label var imd_order 				"Ranking of index of Multiple Deprivation (IMD)"
	label var ethnicity_16				"Ethnicity in 16 categories"
	label var ethnicity_5				"Ethnicity in 5 categories"
	label var stp 						"Sustainability and Transformation Partnership"
	label var stpcode 					"Sustainability and Transformation Partnership"
	label var region_7 					"Geographical region (7 England regions)"
	label var rural						"Rural/urban binary classification"
	label var household_id 				"Household ID"
	label var household_size 			"Household size"
	label var resid_care_old 			"Residential care, elderly"
	label var resid_care_ldr 			"Residential care, learning disability"

	label var smoke		 				"Smoking status"
	label var bmi						"Body Mass Index (BMI, kg/m2)"
	label var bmi_child_date_measured_date "Date BMI measured (if age<16)"


	* Clinical measurements
	label var bp_sys 					"Systolic blood pressure"
	label var bp_sys_date 				"Systolic blood pressure, date"
	label var bp_dias 					"Diastolic blood pressure"
	label var bp_dias_date 				"Diastolic blood pressure, date"
	label var egfr						"Estimated globular filtration rate"
	label var hba1c_pct					"Hba1c percentage"
	label var asthmacat					"Asthma"

	* Dates of comorbidities	
	label var cf_date					"Cystic fibrosis, date"
	label var respiratory_date			"Respiratory disease (excl. asthma), date"
	label var cardiac_date				"Heart disease, date"
	label var af_date					"Atrial fibrillation, date"
	label var dvt_pe_date				"Deep vein thrombosis/pulmonary embolism, date"
	label var pad_surg_date				"Surgery for peripheral arterial disease, date"
	label var amputate_date				"Limb amputation, date"
	label var diabetes_date				"Diabetes, date"
	label var hypertension_date			"Date of diagnosed hypertension"
	label var tia_date					"Transient ischemic attack, date"
	label var stroke_date				"Stroke, date"
	label var dementia_date				"Dementia, date"
	label var neuro_date				"Neuro condition other than stroke/dementia, date"	
	label var lung_cancer_date			"Lung cancer, date"
	label var other_cancer_date			"Other cancer, date"
	label var haem_cancer_date			"Haematological malignancy, date"
	label var liver_date				"Liver, date"
	label var dialysis_date				"Dialysis, date"
	label var transplant_kidney_date	"Kidney transplant recipient, date"
	label var transplant_notkidney_date	"Organ (not kidney) transplant recipient, date"
	label var dysplenia_date			"Dysplenia, date"
	label var sickle_cell_date			"Sickle cell, date"
	label var aplastic_anaemia_date		"Aplastic anaemia, date"
	label var autoimmune_date			"RA, SLE, Psoriasis (autoimmune disease), date"
	label var hiv_date 					"HIV, date"
	label var perm_immuno_date			"Conditions causing permanent immunosuppression, date"
	label var temp_immuno_date			"Conditions causing temporary immunosuppression, date"
	label var ibd_date					"IBD, date"
	label var fracture_date				"Fracture, date"
	label var smi_date 					"Serious mental illness, date"
	label var ldr_date 					"Learning disability register, date"
	label var ld_profound_date			"Profound/severe learning disability, date"
	label var ds_date					"Down's Syndrome, date"
	label var cp_date					"Cerebral Palsy, date"
	 


	* Outcomes 
	label var  coviddeath_date		"Date of ONS COVID-19 death"
	label var  otherdeath_date 		"Date of ONS non-COVID-19 death"
	label var  covidadmission_date	"Date of COVID-19 hospital admission"
			


	*********************
	*  Order variables  *
	*********************

	sort patient_id
	order 	patient_id stp* region_7 imd* rural 						///
			household* resid_care_old resid_care_ldr			 		///
			age male													///
			bmi* smoke* 												///
			ethnicity*													/// 
			respiratory* asthma* cf* cardiac* diabetes* hba1c* 			///
			bp_sys bp_sys_date bp_dias bp_dias_date 					///
			hypertension*												///
			af* dvt_pe* pad* amputate*									///
			stroke* dementia* neuro* tia*								///
			lung_cancer* haem_cancer* other_cancer*						///	
			transplant_kidney* dialysis* liver* transplant_notkidney*	///
			dysplenia* sickle* hiv* perm* temp* aplastic*				///
			autoimmune* ibd* smi* fracture*								///
			smi* ld* fracture*											///
			coviddeath_date otherdeath_date covidadmission_date




			

	***************
	*  Save data  *
	***************

	sort patient_id
	if "`index_date'" == "2020-03-01" {
		label data "Base cohort dataset (wave 1), index date 1st March 2020"
		save "analysis/data_base_cohort1.dta", replace
	}
	else if "`index_date'" == "2020-09-01" {
		label data "Base cohort dataset (wave 2), index date 1st September 2020"
		save "analysis/data_base_cohort2.dta", replace
	}

}
log close

