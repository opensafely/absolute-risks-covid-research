********************************************************************************
*
*	Do-file:		AL006c_cox_regression_interactions_imd.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL006a_cox_regression_inter_age_wave`i'_`out'_`exp'.log
*					Estimates:	output/
*									ldcox_inter_age_wave`i'_`out'_`exp'.out
*
* 						i = Wave (1 or 2)
*						out = outcome (coviddeath covidadmission)
*						exp = exposure (ldr ldr_cat ldr_carecat ds cp ldr_group
*
********************************************************************************
*
*	Purpose:		This do-file fits a series of adjusted Cox models for the
*					learning disability work and obtains the crude rates, 
*					exploring interactions with deprivation (IMD).
*  
********************************************************************************




**********************
*  Input parameters  *
**********************

local wave 		`1'
local outcome  	`2'
local exposure 	`3'

local i = `wave'
local out = "`outcome'"
local exp = "`exposure'"

noi di "Wave:" `i'
noi di "Outcome: `out'"
noi di "Exposure: `exp'"



**************************
*  Adopath and log file  *
**************************

clear all
set more off

* Open a log file
cap log close
log using "logs/AL006c_cox_regression_inter_imd_wave`i'_`out'_`exp'", replace t


* Categories of various exposures
local lo_ldr 		= 0
local hi_ldr 		= 1
local lo_ldr_cat 	= 0
local hi_ldr_cat 	= 2
local hi_ldr 		= 1
local lo_ldr_carecat= 0
local hi_ldr_carecat= 2
local lo_ds 		= 0
local hi_ds 		= 1
local lo_cp 		= 0
local hi_cp 		= 1
local lo_ldr_group 	= 0
local hi_ldr_group 	= 5

* Open temporary file to post results
tempfile ldrfile
tempname ldrresults

postfile `ldrresults' 	wave str15(outcome) str15(exposure) str20(model)	///
						expcat imd lnhr sehr using `ldrfile'


	* Open dataset (complete case ethnicity)
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	drop if ethnicity_5>=.

	* Only keep data for adults
	keep if child==0

	
	/*  Declare data to be survival  */

	stset stime_`out'`i', fail(`out'`i') scale(365.25)

	
		
	/*  Fit Cox models  */
	
	* Confounder only model
	stcox i.`exp'##i.imd age1 age2 age3 male i.ethnicity_5, 	///
		strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i') ("`out'") ("`exp'")		///
				("Confounders") 							///
				(`k') (1) (_b[`k'.`exp']) (_se[`k'.`exp'])
		}
		forvalues l = 2 (1) 5 {
			capture qui di _b[`k'.`exp'#`l'.imd]
			if _rc==0 {
			    lincom `k'.`exp' + `k'.`exp'#`l'.imd
				post `ldrresults' (`i') ("`out'") ("`exp'")		///
					("Confounders") 							///
					(`k') (`l') (r(estimate)) (r(se))
			}
		}
	}

	
	* All variables
	stcox i.`exp'##i.imd age1 age2 age3 male 			///
				i.ethnicity_5 resid_care_ldr 			///
				obese40 								///
				respiratory asthma_severe				///
				cardiac af dvt_pe i.diabcat		 		///
				liver stroke tia dementia				///
				i.kidneyfn								///
				spleen transplant dialysis				///
				immunosuppression i.cancerHaem			///
				autoimmune ibd cancerExhaem1yr, 		///
				strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i') ("`out'") ("`exp'") 	///
			("All") 										///
			(`k') (1) (_b[`k'.`exp']) (_se[`k'.`exp'])
		}
				forvalues l = 2 (1) 5 {
			capture qui di _b[`k'.`exp'#`l'.imd]
			if _rc==0 {
			    lincom `k'.`exp' + `k'.`exp'#`l'.imd
				post `ldrresults' (`i') ("`out'") ("`exp'")	///
					("All") 								///
					(`k') (`l') (r(estimate)) (r(se))
			}
		}
	}

postclose `ldrresults'

use `ldrfile', clear


*************************
*  Tidy output for HRs  *
*************************

* Outcome
rename outcome out
gen outcome 	= 1 if out=="coviddeath"
replace outcome = 2 if out=="covidadmission"
replace outcome = 3 if out=="composite"

label define outcome 	1 "COVID-19 death" 		///
						2 "COVID-19 admission"	///
						3 "Composite"
label values outcome outcome
drop out

* Exposure
rename exposure exp
gen 	exposure = 1 if exp=="ldr"
replace exposure = 2 if exp=="ldr_cat"
replace exposure = 3 if exp=="ldr_carecat"
replace exposure = 4 if exp=="ds"
replace exposure = 5 if exp=="cp"
replace exposure = 6 if exp=="ldr_group"

label define exposure 	1 "Learning disability register"	///
						2 "LDR Severe vs mild"				///
						3 "LDR by residential care"			///
						4 "Down's syndrome"					///
						5 "Cerebral Palsy"					///
						6 "Combined grouping"				
label values exposure exposure						
drop exp

* IMD categories
label define imd 	1 "1 least deprived"	///
					2 "2"					///
					3 "3"					///
					4 "4"					///
					5 "5 most deprived"

label values imd imd


* Categories of exposure
gen category     = "No" 					if expcat==0
replace category = "Yes" 					if inlist(exposure, 1, 4, 5) & expcat==1

replace category = "LDR, mild" 				if inlist(exposure, 2) & expcat==1
replace category = "LDR, profound" 			if inlist(exposure, 2) & expcat==2

replace category = "LDR, community" 		if inlist(exposure, 3) & expcat==1
replace category = "LDR, residential care" 	if inlist(exposure, 3) & expcat==2

replace category = "DS but not LDR" 		if inlist(exposure, 6) & expcat==1
replace category = "DS and LDR" 			if inlist(exposure, 6) & expcat==2
replace category = "CP but not LDR" 		if inlist(exposure, 6) & expcat==3
replace category = "CP and LDR" 			if inlist(exposure, 6) & expcat==4
replace category = "LDR with no DS or CP" 	if inlist(exposure, 6) & expcat==5

* Model adjustment
gen 	adjustment = 1 if model=="Confounders"
replace adjustment = 2 if model=="All"
label define adj 	1 "Confounders"  2 "All"
label values adjustment adj
drop model

* Hazard ratio with 95% confidence interval
gen cl = exp(lnhr - invnorm(0.975)*sehr)
gen cu = exp(lnhr + invnorm(0.975)*sehr)
gen hr = exp(lnhr)

gen hr_ci =   string(round(hr, 0.01)) + " (" ///
			+ string(round(cl, 0.01)) + ", " ///
			+ string(round(cu, 0.01)) + ")"
replace hr_ci = "" if expcat==0
drop cl cu hr lnhr sehr

* Put in wide format
reshape wide hr_ci, i(wave outcome exposure expcat imd) j(adjust)
rename hr_ci1 hr_conf
rename hr_ci2 hr_all

order wave outcome exposure imd category hr*
sort wave outcome exposure imd expcat

* Save data
outsheet using "output/ldcox_inter_imd_wave`i'_`out'_`exp'", replace

log close

