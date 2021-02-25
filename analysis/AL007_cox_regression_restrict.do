********************************************************************************
*
*	Do-file:		AL007_cox_regression_restrict.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL007_cox_regression_restrict_wave`i'_`out'_`exp'.log
*					Estimates:	output/
*									ldcox_restrict_wave`i'_`out'_`exp'.out
*
* 						i = Wave (1 or 2)
*						out = outcome (coviddeath covidadmission)
*						exp = exposure (ldr ldr_cat ldr_carecat)
*
********************************************************************************
*
*	Purpose:		This do-file restricts to adults (16+) who are not already
*					prioritised for vaccination (as best we can tell) and
*					fits a series of adjusted Cox models to estimate hazard
*					ratios for learning disability in that group.
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
log using "logs/AL007_cox_regression_restrict_wave`i'_`out'_`exp'.log", ///
	replace t


* Categories of various exposures
local lo_ldr 		= 0
local hi_ldr 		= 1
local lo_ldr_cat 	= 0
local hi_ldr_cat 	= 2
local hi_ldr 		= 1
local lo_ldr_carecat= 0
local hi_ldr_carecat= 2


* Open temporary file to post results
tempfile ldrfile
tempname ldrresults

postfile `ldrresults' 	wave str15(outcome) str15(exposure) str20(model)	///
						expcat lnhr sehr using `ldrfile'


	* Open dataset (complete case ethnicity)
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 
	drop if ethnicity_5>=.

	* Only keep data for adults
	keep if child==0
	
	
	/*  Exclude people already prioritised for vaccination  */
	
	* Age
	drop if age>=65
	
	* Obesity
	drop if obese40==1
	
	* Respiratory
	drop if respiratory		==1
	drop if asthma_severe	==1
	drop if cf				==1

	* Cardiovascular and neurological
	drop if cardiac			==1
	drop if af				==1
	drop if dvt_pe			==1
	drop if diabcat			>=2
	drop if dementia		==1 
	drop if stroke			==1 
	drop if tia				==1 
	drop if neuro			==1 
	
	* Liver, kidney, and transplant
	drop if liver			==1
	drop if kidneyfn		>=2
	drop if dialysis		==1
	drop if transplant		==1
	
	* Immunosuppression
	drop if spleen			==1
	drop if immunosuppression==1
	drop if cancerHaem		==1
	drop if autoimmune		==1
	drop if ibd				==1
	drop if cancerExhaem1yr	==1

	* Mental illness, Down's syndrome and CP
	drop if smi				==1
	drop if ds				==1
	drop if cp				==1
	 	
	

	/*  Declare data to be survival  */

	stset stime_`out'`i', fail(`out'`i') scale(365.25)

		
		
	/*  Fit Cox models  */
	
	* Confounder only model
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5, 	///
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
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5 imd, ///
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
	stcox i.`exp' age1 age2 age3 male i.ethnicity_5 resid_care_ldr, ///
		strata(stpcode) cluster(household_id) 
	forvalues k = `lo_`exp'' (1) `hi_`exp'' {
		capture qui di _b[`k'.`exp']
		if _rc==0 {
			post `ldrresults' (`i') ("`out'") ("`exp'") 	///
				("Confounders+Resid") 						///
				(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
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
replace category = "Yes" 					if inlist(exposure, 1) & expcat==1

replace category = "LDR, mild" 				if inlist(exposure, 2) & expcat==1
replace category = "LDR, profound" 			if inlist(exposure, 2) & expcat==2

replace category = "LDR, community" 		if inlist(exposure, 3) & expcat==1
replace category = "LDR, residential care" 	if inlist(exposure, 3) & expcat==2


* Model adjustment
gen 	adjustment = 1 if model=="Confounders"
replace adjustment = 2 if model=="Confounders+IMD"
replace adjustment = 3 if model=="Confounders+Resid"
label define adj 	1 "Confounders" 					///	
					2 "Confounders with IMD"			///
					3 "Confounders with care"	
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


order wave outcome exposure category hr*
sort wave outcome exposure expcat

* Save data
outsheet using "output/ldcox_restrict_wave`i'_`out'_`exp'", replace


log close

