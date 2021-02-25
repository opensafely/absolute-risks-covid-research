********************************************************************************
*
*	Do-file:		AL008_cox_regression_noncovid.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL008_cox_regression_noncovid_wave`i'_`exp'.log
*					Estimates:	output/
*									ldcox_noncovid_wave`i'_`exp'.out
*
* 						i = Wave (1 or 2)
*						exp = exposure (ldr ldr_cat ldr_carecat ds cp ldr_group)
*
********************************************************************************
*
*	Purpose:		This do-file fits a series of adjusted Cox models for the
*					outcome of Non-COVID death, for a variety of learning
*					disability related exposures.
*  
********************************************************************************




**********************
*  Input parameters  *
**********************

local wave 		`1'
local exposure 	`2'

local i = `wave'
local exp = "`exposure'"

noi di "Wave:" `i'
noi di "Exposure: `exp'"




**************************
*  Adopath and log file  *
**************************

clear all
set more off

* Open a log file
cap log close
log using "logs/AL008_cox_regression_noncovid_wave`i'_`exp'", replace t

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

postfile `ldrresults' 	wave str15(exposure) str20(model)	///
						expcat lnhr sehr using `ldrfile'


	* Open dataset (complete case ethnicity)
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	drop if ethnicity_5>=.

	* Only keep data for adults
	keep if child==0

	/*  Declare data to be survival  */

	stset stime_noncoviddeath`i', fail(noncoviddeath`i') scale(365.25)


		
	/*  Obtain rates  */
		
	strate `exp', 										///
			output(output/data_temp`i'_`exp', replace) 	///
			per(10000)
		
		
	/*  Fit Cox models  */
	
	* Confounder only model
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5, 	///
		strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i') ("`exp'")			///
				("Confounders") 						///
				(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
		}
	}
	
	* Confounders with deprivation
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5 imd, ///
		strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i') ("`exp'") 			///
				("Confounders+IMD") 					///
				(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
		}		
	}
	
	* Confounders with residential care
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5 resid_care_ldr, ///
		strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i') ("`exp'")		 	///
				("Confounders+Resid") 					///
				(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
		}		
	}
	
	* Confounders with physical comorbidities that are indicators for vaccination 
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5 	///
				obese40 cardiac af dvt_pe i.diabcat		 ///
				liver stroke tia dementia				///
				i.kidneyfn								///
				spleen transplant dialysis				///
				immunosuppression cancerHaem			///
				autoimmune ibd cancerExhaem1yr, 		///
		strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i')  ("`exp'") 		///
			("Confounders+Comorb") 					///
			(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
		}
	}
	
	* All variables
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5 	///
				imd resid_care_ldr obese40				///
				cardiac af dvt_pe i.diabcat		 		///
				liver stroke tia dementia				///
				i.kidneyfn								///
				spleen transplant dialysis				///
				immunosuppression cancerHaem			///
				autoimmune ibd cancerExhaem1yr, 		///
		strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i') ("`exp'") 		///
			("All") 								///
			(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
		}
	}
	

postclose `ldrresults'

use `ldrfile', clear

*************************
*  Tidy output for HRs  *
*************************


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
label define adj 	1 "Confounders" 					///	
					2 "Confounders with IMD"			///
					3 "Confounders with care"			///
					4 "Confounders with comorbidities"	///
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
reshape wide hr_ci, i(wave exposure expcat) j(adjust)
rename hr_ci1 hr_conf
rename hr_ci2 hr_conf_imd
rename hr_ci3 hr_conf_resid
rename hr_ci4 hr_conf_comorb
rename hr_ci5 hr_all


order wave exposure category hr*
sort wave exposure expcat

* Save data
save "output/ldhrs_noncovid_wave`i'_`exp'", replace



***************************
*  Tidy output for rates  *
***************************


use "output/data_temp`i'_`exp'", clear
gen wave = `i'
gen exp = "`exp'"
erase "output/data_temp`i'_`exp'.dta"

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
rename `exp' expcat
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

order wave exposure category events pyr rate*
sort wave exposure expcat


* Save data
save "output/ldrates_noncovid_wave`i'_`exp'", replace



******************************
*  Put output data together  *
******************************

use "output/ldrates_noncovid_wave`i'_`exp'.dta", clear
merge 1:1 exposure expcat using ///
	"output/ldhrs_noncovid_wave`i'_`exp'.dta", assert(match) nogen
order wave exposure expcat
outsheet using "output/ldcox_noncovid_wave`i'_`exp'.out", replace
erase "output/ldrates_noncovid_wave`i'_`exp'.dta"
erase "output/ldhrs_noncovid_wave`i'_`exp'.dta"

log close

