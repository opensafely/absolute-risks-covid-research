********************************************************************************
*
*	Do-file:		AL005_cox_regression_child.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL005_cox_regression_child.log
*					Estimates:	output/
*									ldcox_covidadmission_child.out
*
********************************************************************************
*
*	Purpose:		This do-file fits a series of adjusted Cox models for the
*					learning disability work and obtains the crude rates
*					among children (under 16).
*  
********************************************************************************




clear all
set more off

* Open a log file
cap log close
log using "logs/AL005_cox_regression_child", replace t


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
						expcat lnhr sehr using `ldrfile'

* Cycle over the two waves
*    Wave 1: i=1  (1 Mar 20 - 31 Aug 20) 
*    Wave 2: i=2  (1 Sept 20 - latest)
forvalues i = 1 (1) 2 {

	* Open dataset (complete case ethnicity)
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	drop if ethnicity_5>=.

	* Only keep data for children (under 16)
	keep if child==1

	* Outcome: hospitalisation (insufficient deaths) 
	foreach out in covidadmission {


		/*  Declare data to be survival  */

		stset stime_`out'`i', fail(`out'`i') scale(365.25)


		* Cycle over exposures: learning disability register, by severity, 
		*    Down's syndrome, Cerebral Palsy, and the combined grouping
		foreach exp in ldr ldr_cat ldr_carecat ds cp ldr_group {

		
			/*  Obtain rates  */
			
			strate `exp', 											///
				output(analysis/data_temp`out'_`exp'_`i', replace) 	///
				per(10000)
		
		
			/*  Fit Cox models  */
			
			* Confounder only model
			capture stcox i.`exp' age1 age2 age3 male i.ethnicity_5, 	///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
			    capture qui di _b[`k'.`exp']
				if _rc==0 {
				    post `ldrresults' (`i') ("`out'") ("`exp'")		///
						("Confounders") 							///
						(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
				}
			}
			
			
			* Confounders with deprivation
			capture stcox i.`exp' age1 age2 age3 male i.ethnicity_5 i.imd, ///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
				capture qui di _b[`k'.`exp']
				if _rc==0 {
					post `ldrresults' (`i') ("`out'") ("`exp'") 	///
						("Confounders+IMD") 						///
						(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
				}		
			}
			
			
			* Confounders with residential care
			*	(don't do for exposure split by residential care)
			if "`exp'"=="ldr_carecat" {
				forvalues k = `lo_`exp'' (1) `hi_`exp'' {
					post `ldrresults' (`i') ("`out'") ("`exp'") 	///
						("Confounders+Resid") (`k') (.) (.)
				}
			} 
			else {
				capture stcox i.`exp' age1 age2 age3 male i.ethnicity_5 resid_care_ldr, ///
					strata(stpcode) cluster(household_id) 
				forvalues k = `lo_`exp'' (1) `hi_`exp'' {
					capture qui di _b[`k'.`exp']
					if _rc==0 {
						post `ldrresults' (`i') ("`out'") ("`exp'") 	///
							("Confounders+Resid") 						///
							(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
					}		
				}
			}

	
			* Confounders with physical comorbidities that are indicators for vaccination 
			capture stcox i.`exp' age1 age2 age3 male i.ethnicity_5 	///
						obese40, 										///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
			    capture qui di _b[`k'.`exp']
				if _rc==0 {
				    post `ldrresults' (`i') ("`out'") ("`exp'") 	///
					("Confounders+Comorb") 							///
					(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
				}
			}
			
			
			* All variables
			if "`exp'"=="ldr_carecat" {
				local rc = " "
			}
			else {
				local rc = "resid_care_ldr"
			}

			capture stcox i.`exp' age1 age2 age3 male i.ethnicity_5 	///
						i.imd  `rc' obese40, 							///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
			    capture qui di _b[`k'.`exp']
				if _rc==0 {
				    post `ldrresults' (`i') ("`out'") ("`exp'") 		///
					("All")					 							///
					(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
				}
			}
			
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
replace adjustment = 2 if model=="Confounders+IMD"
replace adjustment = 3 if model=="Confounders+Resid"
replace adjustment = 4 if model=="Confounders+Comorb"
replace adjustment = 5 if model=="All"
label define adj 	1 "Confounders" 				///	
					2 "Confounders with IMD"		///
					3 "Confounders with care"		///
					4 "Confounders with obesity"	///	
					5 "All"	
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
reshape wide hr_ci, i(wave outcome exposure expcat) j(adjust)
rename hr_ci1 hr_conf
rename hr_ci2 hr_conf_imd
rename hr_ci3 hr_conf_resid
rename hr_ci4 hr_conf_obese
rename hr_ci5 hr_conf_all


order wave outcome exposure category hr*
sort wave outcome exposure expcat

* Save data
save "output/output_hrs_main_child", replace



***************************
*  Tidy output for rates  *
***************************

forvalues i = 1 (1) 2 {
	foreach out in covidadmission  {
		local expnow = "ldr"
		use "analysis/data_tempcovidadmission_`expnow'_`i'", clear
		gen exp = "`expnow'"
		foreach exp in ldr_cat ldr_carecat ds cp ldr_group {
			rename `expnow' `exp'
			append using "analysis/data_tempcovidadmission_`exp'_`i'"
			erase "analysis/data_tempcovidadmission_`expnow'_`i'.dta"
			replace exp = "`exp'" if exp==""
			local expnow = "`exp'"
		}
		erase "analysis/data_tempcovidadmission_`expnow'_`i'.dta"
		gen out = "`out'"
		save "analysis/data_tempcovidadmission_`i'", replace
	}
	gen wave = `i'
	save "analysis/data_temp_`i'.dta"
}
use "analysis/data_temp_1.dta"
append using "analysis/data_temp_2.dta"

erase "analysis/data_temp_1.dta"
erase "analysis/data_temp_2.dta"



* Outcome
gen outcome 	= 1 if out=="coviddeath"
replace outcome = 2 if out=="covidadmission"
replace outcome = 3 if out=="composite"

label define outcome 	1 "COVID-19 death" 		///
						2 "COVID-19 admission"	///
						3 "Composite"
label values outcome outcome
drop out

* Exposure
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

* Categories of exposure
rename ldr_group expcat
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

* Rename remaining variables
rename _D events
rename _Y pyr_10000
rename _Rate rate_per_10000
rename _Lower rate_cl
rename _Upper rate_cu

/* Redaction  */ 

** Remove event counts < 5, and complementary counts
gen redact = inlist(events, 1, 2, 3, 4, 5)
bysort wave outcome exposure category: egen redact_group = max(redact)
replace events = -999 if redact_group==1 & !(exposure==6 & expcat==0 & redact==0)
gen events_str = string(events)
replace events_str = "<=5" if events_str=="-999"
order events_str, after(events)
drop events redact redact_group
rename events_str events

order wave outcome exposure category events pyr rate*
sort wave outcome exposure expcat


* Save data
save "output/output_rates_child", replace





******************************
*  Combine HR and rate data  *
******************************

use "output/output_rates_child"
merge 1:1 wave outcome exposure category ///
	using "output/output_hrs_main_child", assert(match) nogen
sort wave outcome exposure category

erase "output/output_rates_child.dta"
erase "output/output_hrs_main_child.dta"

outsheet using "output/ldcox_covidadmission_child.out", replace

log close
