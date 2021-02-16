********************************************************************************
*
*	Do-file:		AAR002_1_risk_by_age.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		analysis/data_aranalysis_cohort`i'.dta
*
*	Data created:	output/ar_wave`i'_male`j'_`outcome.out
*
*	Other output:	Log file:  logs/AAR002_2_risk_by_age
*					output/ar_wave`i'_male`j'_`outcome'.svg
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using Royston-Parmar
*					flexible hazard modelling. 
*
*					These analyses will be helpful in considering how 
*					comorbidities and demographic factors affect risk, 
*					comparatively.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************



* Set wave (i=1 or 2), sex (j=1 (male) or 0 (female) and
*  outcome (coviddeath or covidadmission)
local i = 2
local out = "covidadmission"


* Open a log file
capture log close
log using "logs/AAR002_2_risk_by_age", replace t

* Cycle over men and women
forvalues j = 0 (1) 1 {
		
	****************
	*   Open data  *
	****************

	use "analysis/data_aranalysis_cohort`i'.dta", replace 	
	drop if ethnicity_5>=.
	drop ethnicity_16
	rename ethnicity_5 ethnicity


	* Keep under 50s only
	drop if age>=50


	/*  Declare data to be survival  */

	stset stime_`out'`i'_nocensor, fail(`out'`i'_nocensor) ///
		scale(365.25) id(patient_id)




		
	********************************
	*   Fit Royston-Parmar model   *
	********************************


	* Create dummy variables for categorical predictors 
	foreach var of varlist obesecat smoke_nomiss imd  	///
		asthmacat diabcat cancerExhaem cancerHaem 		///
		kidneyfn region ethnicity						///
		{
			egen ord_`var' = group(`var')
			qui summ ord_`var'
			local max=r(max)
			forvalues i = 1 (1) `max' {
				gen `var'_`i' = (`var'==`i')
			}	
			drop ord_`var'
			drop `var'_1
	}


	timer clear 1
	timer on 1
	stpm2  	age1 age2 age3 	 		///
			ethnicity_*				///
			obesecat_*				///
			smoke_nomiss_*			///
			imd_* 					///
			hypertension			///
			respiratory			 	///
			cf			 			///
			asthmacat_*				///
			cardiac 				///
			diabcat_*				///
			af		 				///
			dvt_pe		 			///
			pad		 				///
			cancerExhaem_*	 		///
			cancerHaem_*  			///
			liver					///
			stroke					///
			dementia		 		///
			tia		 				///
			neuro					///
			kidneyfn_*				///
			transplant 				///
			dialysis 				///
			spleen 					///
			autoimmune  			///
			ibd			  			///
			immunosuppression		///
			smi			  			///
			ds			  			///
			ldr			  			///
			region_*				///
			if male==`j',			///
			scale(hazard) df(10) eform lininit
	estat ic
	timer off 1
	timer list 1
				



	*****************************************************
	*   Survival predictions from Royston-Parmar model  *
	*****************************************************

	* Predict absolute risk at 90 days
	gen time90 = 90
	predict surv90_royp, surv timevar(time90)
	gen risk90_royp = 1-surv90_royp
	drop surv90_royp

	/*  Quantiles of predicted day risk   */

	centile risk90_royp, c(50 70 80 90)

	global p50 = r(c_1) 
	global p70 = r(c_2) 
	global p80 = r(c_3) 
	global p90 = r(c_4) 




	*********************************************************
	*   Obtain predicted risks by comorbidity with 95% CIs  *
	*********************************************************

	* Collapse data to one row per age (i.e. per year)
	bysort age: keep if _n==1

	* Keep only variables needed for the risk prediction
	keep age age? _rcs1- _d_rcs5  _st _d _t _t0

	* Sex
	gen male = `j'

	* Set time to 90 days (for the risk prediction period)
	gen time90 = 90



	/*  Initially set values to "no comorbidity"  */


	foreach var in   											///
		hypertension respiratory cf asthmacat_2 asthmacat_3 	///
		cardiac diabcat_2 diabcat_3	diabcat_4 af dvt_pe pad 	///	
		cancerExhaem_2 cancerExhaem_3 cancerExhaem_4			///
		cancerHaem_2 cancerHaem_3 cancerHaem_4					///
		liver stroke dementia tia neuro							///
		kidneyfn_2 kidneyfn_3 transplant dialysis				///
		spleen autoimmune ibd immunosuppression 				///
		smi ldr ds 	{
		gen `var' = 0
	}


	/*  Non-smoker, non-obese, middle IMD, White, Midlands  */


	foreach var in   											///
		ethnicity_2 ethnicity_3 ethnicity_4 ethnicity_5			///
		smoke_nomiss_2 smoke_nomiss_3 							/// 			 
		obesecat_2 obesecat_3 obesecat_4  						///
		imd_2 imd_3 imd_4 imd_5 								///
		region_2 region_3 region_4 region_5 region_6 region_7 	{
		gen `var' = 0
	}
	replace imd_3    = 1 
	replace region_3 = 1



	/*  Predict survival at 90 days under each comorbidity separately   */

	* Set age and sex to baseline values
	gen cons = 0

	foreach var of varlist cons 							///
			respiratory cf asthmacat_2 asthmacat_3 			///
			cardiac diabcat_2 diabcat_3 diabcat_4 			///
			hypertension af dvt_pe pad 						///	
			cancerExhaem_2 cancerExhaem_3 cancerExhaem_4	///
			cancerHaem_2 cancerHaem_3 cancerHaem_4			///
			liver stroke dementia tia neuro					///
			kidneyfn_2 kidneyfn_3 transplant dialysis		///
			spleen autoimmune ibd immunosuppression 		///
			smi ldr ds 										///
			{
					
		* Reset that value to "yes"
		replace `var' = 1
		
		* Predict under that comorbidity (age and sex left at original values)
		predict pred_`var', surv timevar(time90) ci
		
		* Change to risk, not survival
		gen risk_`var' = 1 - pred_`var'
		gen risk_`var'_uci = 1 - pred_`var'_lci
		gen risk_`var'_lci = 1 - pred_`var'_uci
		drop pred_`var' pred_`var'_lci pred_`var'_uci
		
		* Reset that value back to "no"
		replace `var' = 0
	}

	keep age male risk*


	* Save relevant percentiles
	gen p50 = $p50 
	gen p70 = $p70 
	gen p80 = $p80 
	gen p90 = $p90 


	* Save data
	save "analysis/ar_wave`i'_male`j'_`outcome'", replace
	outsheet using "output/ar_wave`i'_male`j'_`outcome'.out", replace






	*****************************
	*  Graph all comorbidities  *
	*****************************			

	* Graph title and labelling
	local opts = "ylab(0 (0.001) 0.009, angle(0)) xlab(20 (20) 50) xmtick(20 (5) 50)"
		
	local wave1 = "Wave 1"
	local wave2 = "Wave 2"
	local male0 = "Female"
	local male1 = "Male"


	* Risk 
	qui summ risk_cons if age==50 
	gen risk_age_50 = r(mean) 


	* All comorbidities
	sort age
	twoway 	(line risk_respiratory 			age, lwidth(vthin) lcolor(eltblue)) 						///
			(line risk_cf 					age, lwidth(vthin) lcolor(eltblue) lpattern(dash))			///
			(line risk_asthmacat_2 			age, lwidth(vthin) lcolor(blue)) 							///
			(line risk_asthmacat_3			age, lwidth(vthin) lcolor(midblue)) 						///
			(line risk_hypertension 		age, lwidth(vthin) lcolor(olive_teal)) 						///
			(line risk_cardiac 				age, lwidth(vthin) lcolor(mint)) 							///
			(line risk_diabcat_2			age, lwidth(vthin) lcolor(midgreen)) 						///
			(line risk_diabcat_3			age, lwidth(vthin) lcolor(green)) 							///
			(line risk_diabcat_4			age, lwidth(vthin) lcolor(dkgreen)) 						///
			(line risk_liver 				age, lwidth(vthin) lcolor(olive))  							///
			(line risk_kidneyfn_2 			age, lwidth(vthin) lcolor(stone))							///
			(line risk_kidneyfn_3 			age, lwidth(vthin) lcolor(sand))  							///
			(line risk_transplant			age, lwidth(vthin) lcolor(sienna))  						///
			(line risk_dialysis				age, lwidth(vthin) lcolor(sienna*0.7))						///
			(line risk_stroke 				age, lwidth(vthin) lcolor(pink)) 							///
			(line risk_dementia 			age, lwidth(vthin) lcolor(pink) lpattern(dash)) 			///
			(line risk_tia					age, lwidth(vthin) lcolor(pink) lpattern(dot)) 				///
			(line risk_neuro 				age, lwidth(vthin) lcolor(maroon)) 	 						///
			(line risk_cancerExhaem_2 		age, lwidth(vthin) lcolor(gs3) lpattern(dash))	 			///
			(line risk_cancerExhaem_3	 	age, lwidth(vthin) lcolor(gs5) lpattern(dash))	 			///
			(line risk_cancerExhaem_4		age, lwidth(vthin) lcolor(gs7) lpattern(dash))	 			///
			(line risk_cancerHaem_2 		age, lwidth(vthin) lcolor(sandb) lpattern(dash))			///
			(line risk_cancerHaem_3 		age, lwidth(vthin) lcolor(gold) 	lpattern(dash))			///
			(line risk_cancerHaem_4			age, lwidth(vthin) lcolor(yellow) 	lpattern(dash))			///
			(line risk_spleen 				age, lwidth(vthin) lcolor(orange_red)  lpattern(dot))		///
			(line risk_autoimmune 			age, lwidth(vthin) lcolor(magenta)) 	  					///
			(line risk_ibd 					age, lwidth(vthin) lcolor(magenta)) 	  					///
			(line risk_immunosuppression	age, lwidth(vthin) lcolor(red) lpattern(dash))				///
			(line risk_smi					age, lwidth(vthin) lcolor(red) lpattern(dash))				///
			(line risk_ldr					age, lwidth(vthin) lcolor(red) lpattern(dash))				///
			(line risk_ds					age, lwidth(vthin) lcolor(red) lpattern(dash))				///
			(line risk_cons 				age, lwidth(vthin) lcolor(black)) 	  						///
			(line risk_age_50 				age, lpattern(dot) lcolor(black))							///
			, 	`opts' subtitle("`male`j'', `wave`i''")											 		///
			legend(order(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31) ///
			size(tiny) col(4)					///
			label(1 "Respiratory") 				///
			label(2 "CF") 						///
			label(3 "Asthma mild") 				///
			label(4 "Asthma sev") 				///
			label(5 "Hypertension") 			///
			label(6 "Cardiac") 					///
			label(7 "Diab, control") 			/// 
			label(8 "Diab, uncontrol")  		///
			label(9 "Diab, unknown")  			///
			label(10 "Liver")  					///
			label(11 "Red kidney")  			///
			label(12 "Poor kidney")  			///
			label(13 "Transplant")  			///
			label(14 "Dialysis")  				///
			label(15 "Stroke") 					///
			label(16 "Dementia") 				///
			label(17 "TIA") 					///
			label(18 "Neurological") 	 		///
			label(19 "Canc. Oth (<1yr)") 		///
			label(20 "Canc. Oth (2-4yr)") 		///
			label(21 "Canc. Oth (5+yr)") 		///
			label(22 "Canc. Haem (<1yr)") 		///
			label(23 "Canc. Haem (2-4yr)") 		///
			label(24 "Canc. Haem (5+yr)") 		///
			label(25 "Spleen") 					///
			label(26 "RA/SLE/psoriasis") 		///
			label(27 "Immunosuppression") 		///
			label(28 "SMI") 	  				///
			label(29 "Learning disability") 	///
			label(30 "Down's Syndrome") 	  	///
			label(31 "No comorbidity") 	  		///
			colfirst) 
		graph export output/ar_wave`i'_male`j'_`outcome'.svg, as(svg) replace width(1600)
	}
}

log close

