********************************************************************************
*
*	Do-file:		X_covid_outcomes_by_at_risk.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort2.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/X_covid_outcomes_by_at_risk.log
*					Estimates:	output/
*									X_covid_outcomes_by_at_risk.out
*
********************************************************************************
*
*	Purpose:		This do-file restricts to adults (16+) who are not already
*					prioritised for vaccination (as best we can tell) and
*					fits a series of adjusted Cox models to estimate hazard
*					ratios for learning disability in that group.
*  
********************************************************************************






**************************
*  Adopath and log file  *
**************************

clear all
set more off

* Open a log file
cap log close
log using "logs/X_covid_outcomes_by_at_risk.log", replace t


* Open dataset (complete case ethnicity)
use "analysis/data_ldanalysis_cohort2.dta", clear 
drop if ethnicity_5>=.

* Only keep data for adults
keep if child==0

* Drop people who died prior to 7 Dec 2020
drop if coviddeath_date<d(7dec2020)
drop if otherdeath_date<d(7dec2020)


/*  Create "at risk" indicator  */

gen atrisk = 0

* Obesity
replace atrisk = 1 if obese40==1

* Respiratory
replace atrisk = 1 if respiratory	==1
replace atrisk = 1 if asthma_severe	==1
replace atrisk = 1 if cf			==1

* Cardiovascular and neurological
replace atrisk = 1 if cardiac		==1
replace atrisk = 1 if af			==1
replace atrisk = 1 if dvt_pe		==1
replace atrisk = 1 if diabcat		>=2
replace atrisk = 1 if dementia		==1 
replace atrisk = 1 if stroke		==1 
replace atrisk = 1 if tia			==1 
replace atrisk = 1 if neuro			==1 

* Liver, kidney, and transplant
replace atrisk = 1 if liver			==1
replace atrisk = 1 if kidneyfn		>=2
replace atrisk = 1 if dialysis		==1
replace atrisk = 1 if transplant	==1

* Immunosuppression
replace atrisk = 1 if spleen			==1
replace atrisk = 1 if immunosuppression==1
replace atrisk = 1 if cancerHaem		>1
replace atrisk = 1 if autoimmune		==1
replace atrisk = 1 if ibd				==1
replace atrisk = 1 if cancerExhaem1yr	==1

* Mental illness, Down's syndrome and CP
replace atrisk = 1 if smi			==1
replace atrisk = 1 if ds			==1
replace atrisk = 1 if cp			==1

noi tab atrisk

/*  Create outcome indicators  */

* Drop binary indicators
drop coviddeath2 covidadmission2 composite2 composite_date

* Ignore events after 22 Feb 2021
replace coviddeath_date 	= . if coviddeath_date     > d(22feb2021)
replace covidadmission_date = . if covidadmission_date > d(22feb2021)

* Create new binary indicators (for the 12 week period of interest)
gen coviddeath     = (coviddeath_date<.)
gen covidadmission = (covidadmission_date<.)
gen composite = max(coviddeath, covidadmission)

noi tab atrisk coviddeath
noi tab atrisk covidadmission
noi tab atrisk composite


keep age atrisk coviddeath covidadmission composite

/*  Recode age  */

recode age  16/19=1		///
			20/24=2 	///
			25/29=3		///
			30/34=4		///
			35/39=5		///
			40/44=6		///
			45/49=7		///
			50/54=8		///
			55/59=9		///
			60/64=10	///
			65/69=11	///
			70/74=12	///
			75/79=13	///
			80/84=14	///
			85/89=15	///
			90/99=16	///
			100/105=17, gen(agegp)
label define agegp		///
			1 "16-19"	///
			2 "20-24"	///
			3 "25-29"	///
			4 "30-34"	///
			5 "35-39"	///
			6 "40-44"	///
			7 "45-49"	///
			8 "50-54"	///
			9 "55-59"	///
			10 "60-64"	///
			11 "65-69"	///
			12 "70-74"	///
			13 "75-79"	///
			14 "80-84"	///
			15 "85-89"	///
			16 "90-99"	///
			17 "100-105"
label values agegp agegp
drop age
tab agegp, m

noi tab agegp atrisk


* Open temporary file to post results
tempfile riskfile
tempname riskresults

postfile `riskresults' 	age atrisk str15(outcome) natrisk	///
						nout using `riskfile'

	* Cycle over age-group
	forvalues i = 1 (1) 17 {
		* Cycle over "at risk" and not  
		forvalues j = 0 (1) 1 {
			count if atrisk==`j' & agegp==`i'
			local n`j'_age`i' = r(N)
			* Cycle over three outcomes
			foreach out in coviddeath covidadmission composite {
				count if atrisk==`j' & agegp==`i' & `out'==1
				post `riskresults' (`i') (`j') ("`out'") (`n`j'_age`i'') (r(N))
			}
		}
	}	

postclose `riskresults'

use `riskfile', clear



*************************
*  Tidy output for HRs  *
*************************

* Outcome
rename outcome out
gen outcome 	= 1 if out=="coviddeath"
replace outcome = 2 if out=="covidadmission"
replace outcome = 3 if out=="composite"
drop out

reshape wide natrisk nout, i(age atrisk) j(outcome)
drop natrisk2 natrisk3
rename natrisk1 natrisk
rename nout1 ncoviddeath
rename nout2 ncovidadmission
rename nout3 ncomposite

save temp, replace


* Open temporary file to post results
tempfile riskfile2
tempname riskresults2

postfile `riskresults2' age atrisk str15(outcome) rr cl cu	///
						using `riskfile2'

						
* Cycle over three outcomes
foreach out in coviddeath covidadmission composite {

	use temp, clear
	expand 2
	bysort age atrisk: gen case=(_n==2)
	gen     n = natrisk-n`out' 	if case==0
	replace n = n`out' 			if case==1
	
	* Cycle over age-group
	forvalues i = 1 (1) 17 {
		post `riskresults2' (`i') (0) ("`out'") (1) (.) (.) 
		capture cs case atrisk [fw=n] if age==`i'
		if _rc!=0 {
			post `riskresults2' (`i') (1) ("`out'") (.) (.) (.)
		}
		else {
			post `riskresults2' (`i') (1) ("`out'") (r(rr)) (r(lb_rr)) (r(ub_rr))
		}
	}
}


postclose `riskresults2'

use `riskfile2', clear
* Outcome
rename outcome out
gen outcome 	= 1 if out=="coviddeath"
replace outcome = 2 if out=="covidadmission"
replace outcome = 3 if out=="composite"
drop out

reshape wide rr cl cu, i(age atrisk) j(outcome)
rename rr1 rr_coviddeath
rename cl1 cl_coviddeath
rename cu1 cu_coviddeath

rename rr2 rr_covidadmission
rename cl2 cl_covidadmission
rename cu2 cu_covidadmission

rename rr3 rr_composite
rename cl3 cl_composite
rename cu3 cu_composite

merge 1:1 age atrisk using temp, assert(match) nogen
order age atrisk natrisk  													///
 ncoviddeath 	rr_coviddeath 		cl_coviddeath 		cu_coviddeath		///
 ncovidadmission rr_covidadmission 	cl_covidadmission 	cu_covidadmission	///
 ncomposite  	rr_composite 		cl_composite  		cu_composite 		
erase temp.dta



* Some automated redaction 
foreach var of varlist natrisk ncoviddeath ncovidadmission ncomposite {
	gen `var'str = string(`var')
	replace `var'str = "<5" if `var'<=5
	order `var'str, after(`var')
	drop `var'
	rename `var'str `var'
}

* Save data
outsheet using "output/X_covid_outcomes_by_at_risk", replace

log close

