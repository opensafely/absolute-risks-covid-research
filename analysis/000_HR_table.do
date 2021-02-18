********************************************************************************
*
*	Do-file:			000_HR_table.do
*
*	Written by:			Fizz & John
*
*	Data used:			None
*
*
*	Data created:		None
*
*	Other output:		Programs defined in this do-file: 	
*							outputHR_cat  - writes categorical HR to file
*							outputHR_cts  - writes continuous HR to file
*							term_to_text  - converts Stata variable name to text 
*
********************************************************************************
*
*	Purpose:			This do-file reads in model estimates in Stata format
*						and formats them nicely for Word tables.
*
*						Note: the program is fairly specific to the context.
*	
********************************************************************************



***********************************
*  Program: Output Hazard Ratios  *
***********************************

* Generic code to ouput the HRs across outcomes for all levels of a particular
* variable, in the right shape for table
capture program drop outputHR_cat
program define outputHR_cat

	syntax, variable(string) vartext(string)

	* Put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents ("`vartext'") _tab
		
	* Write the hazard ratios to the output file
	capture lincom `variable', eform
	file write tablecontents %4.2f (r(estimate)) (" (") %4.2f (r(lb)) (", ") %4.2f (r(ub)) (")") 

end


* Generic code to ouput the HRs across outcomes for all levels of a particular
* variable, in the right shape for table
capture program drop outputHR_cts
program define outputHR_cts

	syntax, variable(string)  vartext(string)

	* Put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents ("`vartext'")   _tab
		
	* Write the hazard ratios to the output file
	capture lincom c.`variable', eform
	file write tablecontents %4.2f (r(estimate)) (" (") %4.2f (r(lb)) (",") %4.2f (r(ub)) (")")  

end






********************************************
*  Program: Obtain text for term in model  *
********************************************


capture program drop term_to_text
program define term_to_text, rclass
	syntax, term(string)

	* Yes/No variables
	local text_hypertension		= "Hypertension"
	local text_cardiac 			= "Cardiac disease"
	local text_af 				= "Atrial Fibrillation"
	local text_dvt_pe  			= "DVT/PE"
	local text_pad 				= "Surgery for PAD"
	local text_stroke			= "Stroke"
	local text_dementia 		= "Dementia"
	local text_tia 				= "TIA"
	local text_neuro 			= "Other neurological"
	local text_cf 				= "Cystic Fibrosis"
	local text_respiratory		= "Respiratory"
	local text_liver 			= "Liver disease"
	local text_dialysis 		= "Dialysis"
	local text_transplant 		= "Organ transplant"
	local text_autoimmune 		= "RA/SLE/Psoriasis"
	local text_spleen 			= "Asplenia"
	local text_immunosuppression	= "Immunosuppression"
	local text_ibd 				= "IBD"
	local text_ldr 				= "Learning disability register"
	local text_ds 				= "Down's syndrome"
	local text_smi 				= "Serious mental illness"
	local text_fracture  		= "Fracture"

	foreach var in  							///
		hypertension	 						///
		cardiac af dvt_pe pad stroke			/// 
		dementia tia neuro cf respiratory		///
		liver dialysis transplant 				///
		autoimmune spleen immunosuppression 	///
		hiv ibd ldr ds smi fracture 			///
		  {
			if regexm("`term'", "0.`var'") | regexm("`term'", "0b.`var'")  {
				local term = subinstr("`term'", "0.`var'", "No "+lower("`text_`var''"), . )
				local term = subinstr("`term'", "0b.`var'", "No "+lower("`text_`var''"), . )
			}
			if regexm("`term'", "1.`var'") | regexm("`term'", "1b.`var'") {
				local term = subinstr("`term'", "1.`var'", "`text_`var''", . )
				local term = subinstr("`term'", "1b.`var'", "`text_`var''", . )
			}
		}

	* Continuous variables - Age
	forvalues j = 1 (1) 3 {
		local term = subinstr("`term'", "age`j'", "Age (spline `j')", . )
	}
	
	* Deprivation
	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'.imd") | regexm("`term'", "`i'b.imd")  {
			local term = subinstr("`term'", "`i'.imd", "IMD `i'", . )
			local term = subinstr("`term'", "`i'b.imd", "IMD `i'", . )
		}
	}
 	
	* Ethnicity
	local text_eth_1 = "Ethnicity: White"
	local text_eth_2 = "Ethnicity: Mixed"
	local text_eth_3 = "Ethnicity: South Asian"
	local text_eth_4 = "Ethnicity: Black"
	local text_eth_5 = "Ethnicity: Other"

	forvalues i= 1 (1) 8 {
		if regexm("`term'", "`i'.ethnicity_5") | regexm("`term'", "`i'b.ethnicity_5")  {
			local term = subinstr("`term'", "`i'.ethnicity_5", 	"`text_eth_`i''", . )
			local term = subinstr("`term'", "`i'b.ethnicity_5", "`text_eth_`i''", . )
		}
	}
 
	* Obesity
	local text_obese_1 = "BMI: Underweight"
	local text_obese_2 = "BMI: Normal/overweight"
	local text_obese_3 = "BMI: Obese I "
	local text_obese_4 = "BMI: Obese II"
	local text_obese_5 = "BMI: Obese III"

	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'.obesecat") | regexm("`term'", "`i'b.obesecat")  {
			local term = subinstr("`term'", "`i'.obesecat", 	"`text_obese_`i''", . )
			local term = subinstr("`term'", "`i'b.obesecat", "`text_obese_`i''", . )
		}
	}
	
	* Smoking
	local text_smoke_1 = "Never smoker"
	local text_smoke_2 = "Former smoker"
	local text_smoke_3 = "Current smoker"

	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'.smoke") | regexm("`term'", "`i'b.smoke")  {
			local term = subinstr("`term'", "`i'.smoke_nomiss", 	"`text_smoke_`i''", . )
			local term = subinstr("`term'", "`i'b.smoke_nomiss", "`text_smoke_`i''", . )
		}
	}
 
  
	* Diabetes
	local text_diab_1 = "Diabetes: None"
	local text_diab_2 = "Diabetes: Controlled"
	local text_diab_3 = "Diabetes: Uncontrolled"
	local text_diab_4 = "Diabetes: Control unknown"

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'.diabcat") | regexm("`term'", "`i'b.diabcat")  {
			local term = subinstr("`term'", "`i'.diabcat", 	"`text_diab_`i''", . )
			local term = subinstr("`term'", "`i'b.diabcat", "`text_diab_`i''", . )
		}
	}
 
   
	* Asthma
	local text_asthma_1 = "Asthma: None"
	local text_asthma_2 = "Asthma: Without OCS"
	local text_asthma_3 = "Asthma: With OCS"

	forvalues i= 1 (1) 3 {
		if regexm("`term'", "`i'.asthmacat") | regexm("`term'", "`i'b.asthmacat") {
			local term = subinstr("`term'", "`i'.asthmacat", 	"`text_asthma_`i''", . )
			local term = subinstr("`term'", "`i'b.asthmacat", "`text_asthma_`i''", . )
		}
	}
	
	* Cancer
	local text_cancer_1 = "Never"
	local text_cancer_2 = "Last year"
	local text_cancer_3 = "2-5 years ago"
	local text_cancer_4 = "5+ years ago"

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'.cancerExhaem") | regexm("`term'", "`i'b.cancerExhaem")  {
			local term = subinstr("`term'", "`i'.cancerExhaem",   "Cancer (ex haem): `text_cancer_`i''", . )
			local term = subinstr("`term'", "`i'b.cancerExhaem", "Cancer (ex haem): `text_cancer_`i''", . )
			local term = subinstr("`term'", "`i'cancerExhaem", "Cancer (ex haem): `text_cancer_`i''", . )
		}
		if regexm("`term'", "`i'.cancerHaem") | regexm("`term'", "`i'b.cancerHaem")  {
			local term = subinstr("`term'", "`i'.cancerHaem",   "Cancer (haem): `text_cancer_`i''", . )
			local term = subinstr("`term'", "`i'b.cancerHaem", "Cancer (haem): `text_cancer_`i''", . )
		}
	}
	
	* Kidney function
	local text_kf_1 = "Renal impairment: None"
	local text_kf_2 = "Renal impairment: Stage 3a/3b"
	local text_kf_3 = "Renal impairment: Stage 4/5"

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'.kidneyfn") | regexm("`term'", "`i'b.kidneyfn")  {
			local term = subinstr("`term'", "`i'.kidneyfn", 	 "`text_kf_`i''", . )
			local term = subinstr("`term'", "`i'b.kidneyfn", "`text_kf_`i''", . )
		}
	}
 	
	
	* Other auxilliary terms
	local term = subinstr("`term'", "_cons",   "Constant", . )

	* Return parsed and tidied term
	return local term "`term'"

end






**********************************
*  Program: Create table of HRs  *
**********************************



capture program drop crtablehr
program define crtablehr

	syntax , estimates(string) outputfile(string) [roy]

	capture file close tablecontents
	file open tablecontents using `outputfile', t w replace 

	* Extract estimates of desired model
	estimates use `estimates'
	global vars: colnames e(b)
		
	local new = 0
	local currenttype=1
	
	* Loop over variables (terms) in model
	tokenize $vars
	while "`1'"!= "" {
		if !regexm("`1'", "o\.") {
				term_to_text, term("`1'")
				local termtext = r(term)
			
			if regexm("`1'", "b\.") {
				file write tablecontents ("`termtext' (Ref)")  _tab %4.2f (1)		
			}
			else {
				* Print HRs and 95% CIs
				if regexm(substr("`1'", 1, 1), "[0-9]") {
					outputHR_cat, variable("`1'") vartext("`termtext'")
				}
				else {
					outputHR_cts, variable("`1'") vartext("`termtext'")
				}
			}
			file write tablecontents _n
		}
		macro shift
		local new = 0
	}

	file close tablecontents
end



