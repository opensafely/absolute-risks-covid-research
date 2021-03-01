********************************************************************************
*
*	Do-file:		AL003_cumulative_incidence.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		analysis/
*							data_ldanalysis_cohort1.dta
*
*	Data created:	None
*
*	Other output:	Log file:  logs/AL003_cumulative_incidence.log
*					Graph:	output/
*								cumincidence_coviddeath.svg
*								cumincidence_composite.svg
*
********************************************************************************
*
*	Purpose:		This do-file graphs the cumulative incidence of learning
*					disability for adults.
*  
********************************************************************************


clear all
set more off

* Open a log file
cap log close
log using "logs/AL003_cumulative_incidence", replace t

adopath ++ `c(pwd)'/analysis/ado

* Open data (complete case ethnicity for adults (16+))
use "analysis/data_ldanalysis_cohort1", clear
drop if ethnicity_5>=.
keep if child==0

* Cycle over outcomes: mortality, composite (hospitalisation or mortality) 
foreach out in coviddeath composite {

	/*  Declare data to be survival  */

	stset stime_`out'2, fail(`out'2) 
	
	* Fit flexible survival model, adjusting for sex age and ethnicity
	xi i.ethnicity_5 i.male 
	stpm2 ldr age1 age2 age3  _I*, df(4) scale(hazard) eform lininit

	summ _t 
	local tmax=r(max)
	local tmaxplus1=r(max)+1

	range timevar 0 `tmax' `tmaxplus1'
	stpm2_standsurv, 							///
		at1(ldr 0) at2(ldr 1) timevar(timevar) 	///
		ci contrast(difference) fail

	gen date = d(1/3/2020) + timevar 
	format date %tddd_Month

	* Convert to % incidence scale
	for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci: replace X=100*X

	* Print estimates
	l date timevar _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if timevar<.

	* Graph titles
	local title_coviddeath = "Cumulative mortality (%)"
	local label_coviddeath = "0(0.25)0.1"

	local title_composite = "Cumulative mortality or admission (%)"
	local label_composite = "0(0.25)1.9"
	
	
	* Graph
	twoway 	(rarea _at1_lci _at1_uci date, color(red%25)) 	///
			(rarea _at2_lci _at2_uci date, color(blue%25)) 	///
			(line _at1 date, sort lcolor(red)) 				///
			(line _at2 date, sort lcolor(blue)) 			///
			,												///
			legend(order(1 "Not on LDR" 2 "On LDR") 		///
				ring(0) cols(1) pos(11)) 					///
			ylabel(`label_`out'',angle(h) format(%4.2f)) 	///
			ytitle("`title_`out''") 						///
			xtitle("Date in 2020")

	
	* Save graph
	graph export "output/cumincidence_`out'.svg", as(svg) replace
	
	drop _at* _contrast* _I* _rcs* _d_rcs* timevar date
	
}
		 
log close




