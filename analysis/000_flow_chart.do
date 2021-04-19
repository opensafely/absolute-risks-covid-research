********************************************************************************
*
*	Do-file:		000_flow_chart.do
*
*	Programmed by:	Fizz 
*
*	Data used:		input_flow_chart_`t'.csv, 
*						with t=2020-03-01 (wave 1) or t=2020-09-01 (wave 2)
*
*	Data created:  	None
*
*	Other output:	Log file:  logs/000_flow_chart.log
*
********************************************************************************
*
*	Purpose:		This do-file reads in the input data and creates a flow
*					chart, showing numbers included and excluded, for each
*					of the two cohorts.
*  
********************************************************************************


clear all
set more off

* Open a log file
cap log close
log using "logs/000_flow_chart", replace t


forvalues i = 1 (1) 2 {

	* Index date
	if `i'==1 {
	    local index_date = "2020-03-01"
	}
	else if `i'==2 {
	    local index_date = "2020-09-01"	    
	}
	
	noi di "*******************************************************************"
	if `i'==1 {
	   noi di "First cohort, index `index_date'"
	}
	else if `i'==2 {
	   noi di "Second cohort, index `index_date'"
	}
	noi di "*******************************************************************"
	
	* Display the input parameter (index date for cohort)
	local index = date(subinstr("`index_date'", "-", "/", .), "YMD")
	
	* Import data
	import delimited output/input_flow_chart_`index_date'.csv, clear

	* Total
	qui count
	noi di "Patients in import: "  _col(60) r(N)

	* Registered as of index date
	qui count if alive_at_cohort_start!=1
	noi di _col(10) "- Not registered at index date:" _col(65) r(N)
	qui drop if alive_at_cohort_start!=1
	qui count
	noi di "Registered at index date: "  _col(60) r(N)
	
	* Dead prior to index date (late de-registrations)
	qui confirm string variable died_date_ons
	qui gen temp = date(died_date_ons, "YMD")
	qui count if temp < `index'
	noi di _col(10) "- Not alive at index date:" _col(65) r(N)
	qui drop if temp < `index'
	qui count
	noi di "Alive at index date: "  _col(60) r(N)
	
	* Age: Missing
	qui count if age>=.
	noi di _col(10) "- Age missing:" _col(65) r(N)
	qui drop if age>=.
	qui count
	noi di "Age recorded: "  _col(60) r(N)

	* Age: >105
	qui count if age>105
	noi di _col(10) "- Age greater than 105:" _col(65) r(N)
	qui drop if  age>105
	qui count
	noi di "Age <= 105: "  _col(60) r(N)

	* Age: <0
	qui count if age<0
	noi di _col(10) "- Age less than 0:" _col(65) r(N)
	qui drop if  age<0
	qui count
	noi di "Age between 0 and 105: "  _col(60) r(N)
	
	* Sex: Exclude categories other than M and F
	qui count if inlist(sex, "I", "U")
	noi di _col(10) "- Sex not M/F:" _col(65) r(N)
	qui drop if inlist(sex, "I", "U")
	qui count
	noi di "Sex not M/F: "  _col(60) r(N)

	* STP: Missing
	qui count if stp==""
	noi di _col(10) "- Missing STP:" _col(65) r(N)
	qui drop if inlist(sex, "I", "U")
	qui count
	noi di "STP recorded: "  _col(60) r(N)
	
	* Deprivation: Missing 
	qui count if imd>=. | imd==-1
	noi di _col(10) "- Missing deprivation (IMD):" _col(65) r(N)
	qui drop if imd>=. | imd==-1
	qui count
	noi di "IMD available: "  _col(60) r(N)
	
	* Ethnicity: Missing (only excluded in complete case)
	qui count if ethnicity>=. 
	noi di _col(10) "- Missing ethnicity:" _col(65) r(N)
	qui drop if ethnicity>=.
	qui count
	noi di "Ethnicity available: "  _col(60) r(N)
		
}
log close

