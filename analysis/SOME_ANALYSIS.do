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




clear all
set more off

* Open a log file
cap log close
*log using "logs/002_create_ld_analysis_dataset", replace t


local lo_ldr 		= 0
local hi_ldr 		= 1
local lo_ldr_cat 	= 0
local hi_ldr_cat 	= 2
local lo_ds 		= 0
local hi_ds 		= 1
local lo_cp 		= 0
local hi_cp 		= 1
local lo_ldr_group 	= 0
local hi_ldr_group 	= 5


tempfile ldrfile
tempname ldrresults

postfile `ldrresults' 	wave str15(outcome) str15(exposure) str20(model)	///
						expcat lnhr sehr using `ldrfile'

	* Cycle over the two waves
	*    Wave 1: i=1  (1 Mar 20 - 31 Aug 20) 
	*    Wave 2: i=2  (1 Sept 20 - latest)
	local i = 1

	* Open dataset
	use "analysis/data_ldanalysis_cohort`i'.dta", clear 


	* Cycle over outcomes: mortality, hospitalisation, composite 
	foreach out in coviddeath covidadmission composite {


		/*  Declare data to be survival  */

		stset stime_`out'`i', fail(`out'`i') 


		* Cycle over exposures: learning disability register, by severity, 
		*    Down's syndrome, Cerebral Palsy, and the combined grouping
		foreach exp in ldr ldr_cat ds cp ldr_group {

			/*  Fit Cox models  */
			
			* Confounder only model
			stcox i.`exp' age1 age2 age3 male i.ethnicity_5, ///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
			    post `ldrresults' (`i') ("`out'") ("`exp'")	///
					("Confounders") 						///
					(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
			}
			
			* Confounders with deprivation
			stcox i.`exp' age1 age2 age3 male i.ethnicity_5 imd, ///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
				post `ldrresults' (`i') ("`out'") ("`exp'") ///
					("Confounders+IMD") 					///
					(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
			}				
			* Confounders with residential care
			stcox i.`exp' age1 age2 age3 male i.ethnicity_5 resid_care_ldr, ///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
				post `ldrresults' (`i') ("`out'") ("`exp'") ///
					("Confounders+Resid") 					///
					(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
			}				
			* Confounders with physical comorbidities that are indicators for vaccination 
			stcox i.`exp' age1 age2 age3 male i.ethnicity_5 	///
						cardiac af dvt_pe i.diabcat		 		///
						liver stroke tia dementia				///
						i.kidneyfn								///
						spleen transplant dialysis				///
						immunosuppression cancerHaem			///
						autoimmune ibd cancerExhaem1yr, 		///
				strata(stpcode) cluster(household_id) 
			forvalues k = `lo_`exp'' (1) `hi_`exp'' {
				post `ldrresults' (`i') ("`out'") ("`exp'") 	///
					("Confounders_Comorb") 						///
					(`k') (_b[`k'.`exp']) (_se[`k'.`exp'])
			}
		}
	}


	postclose `ldrresults'


		use `ldrfile', clear

			
* interactions:: resid_care_ldr and then broad age
 

log close

