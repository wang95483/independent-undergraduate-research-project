* Copyright (c) [2025] [Haoling Wang]
* All Rights Reserved.
* If you want to use these code, please contact: hmyhw8@nottingham.edu.cn (or the personal email, wang95483@gmail.com)


*begin coding
cd "/Users/wanghaoling/Desktop/mypaper/European_Commission/2st_revised"
import excel "1524.xlsx", firstrow clear 


label variable capex "Capital expenditure (€mn)"
label variable sales "Net sales (€mn)"
label variable Rdinput "R&D input (€mn)"

describe

*clean data
misstable summarize

*data type transfer
destring year, replace ignore(".") force
foreach var in employees profits sales capex Rdinput {
    destring `var', replace ignore(".") force
}
summarize Rdinput sales profits capex employees, detail

*panel data
encode company, gen(company_id)
label list company_id
xtset company_id year

ipolate sales year, gen(sales_i) by(company_id)
ipolate profits year, gen(profits_i) by(company_id)
ipolate capex year, gen(capex_i) by(company_id)
summarize sales sales_i profits profits_i capex capex_i 


drop sales profits capex 
rename sales_i sales
rename profits_i profits
rename capex_i capex

summarize

save "phar1089_cleaned.dta", replace
