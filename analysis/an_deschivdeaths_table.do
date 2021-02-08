*an_deschivdeaths_table
*KB 10/7/2020

run global

*******************************************************************************
*Generic code to output one row of table
cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) 
safecount if hiv==1
local hivdenom = r(N)
safecount if `variable' `condition' & hiv==1
file write descdeathstable ("`variable'") _tab ("`condition'") _tab (r(N)) (" (") %2.0f (100*(r(N))/`hivdenom') (")") _tab
safecount if hiv==0
local nohivdenom = r(N)
safecount if `variable' `condition' & hiv==0
file write descdeathstable (r(N)) (" (") %2.0f (100*(r(N))/`nohivdenom') (")") _n
end

use "an_impute_imputeddata" if _d==1, clear

cap file close descdeathstable
file open descdeathstable using ./output/an_deschivdeaths_table.txt, write text replace

*safecount
*file write descdeathstable ("N deaths") _tab _tab (r(N)) _n _n
gen cons=1
generaterow, variable(cons) condition(==1)
file write descdeathstable _n _n
generaterow, variable(agegroup) condition(<4)
generaterow, variable(agegroup) condition(>=4)
file write descdeathstable _n _n
generaterow, variable(male) condition(==1)
generaterow, variable(male) condition(==0)
file write descdeathstable _n _n
generaterow, variable(obese4cat) condition(==1)
generaterow, variable(obese4cat) condition(>=2)
file write descdeathstable _n _n
generaterow, variable(ethnicity) condition(==4)
generaterow, variable(ethnicity) condition(!=4)
file write descdeathstable _n _n
generaterow, variable(hypertension) condition(==1)
generaterow, variable(diabetes) condition(==1)
generaterow, variable(reduced_kidney_function) condition(>=2)

gen anycomorbidity = 						///
	hypertension					///
	|chronic_respiratory_disease 	///
	|(asthmacat>1)					///
	|chronic_cardiac_disease 		///
	|(diabcat>1)					///
	|(cancer_exhaem_cat>1) 			///
	|(cancer_haem_cat>1)			///
	|chronic_liver_disease 			///
	|stroke_dementia		 		///
	|other_neuro					///
	|(reduced_kidney_function_cat>1)	///
	|organ_transplant 				///
	|spleen 						///
	|ra_sle_psoriasis  				///
	|other_imm_except_hiv	
	
gen anycomorbidityexht = 						///
	chronic_respiratory_disease 	///
	|(asthmacat>1)					///
	|chronic_cardiac_disease 		///
	|(diabcat>1)					///
	|(cancer_exhaem_cat>1) 			///
	|(cancer_haem_cat>1)			///
	|chronic_liver_disease 			///
	|stroke_dementia		 		///
	|other_neuro					///
	|(reduced_kidney_function_cat>1)	///
	|organ_transplant 				///
	|spleen 						///
	|ra_sle_psoriasis  				///
	|other_imm_except_hiv	

generaterow, variable(anycomorbidity) condition(==1)
generaterow, variable(anycomorbidityexht) condition(==1)

	
file write descdeathstable _n _n _n ("ALL Comorbs (counts under 5 redacted to .)")
foreach var of varlist 	hypertension	///
			chronic_respiratory_disease ///
			chronic_cardiac_disease 	///
			chronic_liver_disease 		///
			stroke_dementia		 		///
			other_neuro					///
			organ_transplant 			///
			spleen 						///
			ra_sle_psoriasis  			///
			other_imm_except_hiv 		///
			hepc {
			generaterow, variable(`var') condition(==1)
			}			

foreach var of varlist asthmacat	///
			diabcat					///
			cancer_exhaem_cat	 	///
			cancer_haem_cat  		///
			reduced_kidney_function_cat	{
			generaterow, variable(`var') condition(>=2)
			}					




file close descdeathstable


