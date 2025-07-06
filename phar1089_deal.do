*working on data
cd "/Users/wanghaoling/Desktop/mypaper/European_Commission/2st_rivised/"
*print some basic information
use "phar1089_cleaned.dta", clear

*command installment
ssc install estout
ssc install outreg2

*variable adjustment and description
*diminishing margianl return
gen capex2=capex^2

*改变variable形式来检验显著性
gen lnRdinput=ln(Rdinput)
gen lnprofits=ln(profits)
gen lncapex=ln(capex)
gen lnemployees=ln(employees)
gen lnsales=ln(sales)

*lagged variables
gen L1_sales = L.sales
gen L2_sales = L2.sales
gen L1_profits = L.profits
gen L2_profits = L2.profits
gen L1_Rdinput = L.Rdinput
gen L2_Rdinput = L2.Rdinput
gen L1_capex=L.capex
gen L1_capex2=L.capex2
gen L2_capex=L2.capex
gen L2_capex2=L2.capex2

*interaction term
gen regionbinary = (region == "China")
gen regemp=regionbinary*employees
gen regprof=regionbinary*profits
gen regcap=regionbinary*capex

label variable regemp "number of emloyees in different region"
label variable regprof "profits in different region"
label variable regcap "capital expenditure in different region"
label variable lnRdinput "log of RDinput"
label variable lnprofits "log of profits"
label variable lncapex "log of capital expenditure"
label variable lnemployees "log of number of employees"
label variable lnsales "log of sales"
label variable capex2 "square of capital expenditure"

gen L1_lnsales = L.lnsales
gen L2_lnsales = L2.lnsales
gen L1_lnprofits = L.lnprofits
gen L2_lnprofits = L2.lnprofits
gen L1_lnRdinput = L.lnRdinput
gen L2_lnRdinput = L2.lnRdinput

describe
summarize
*import the summary table
outreg2 using sum.doc,replace sum(log) title(Descriptive statistic)

*Boxplot
graph box sales, over(country, label(angle(45)))
graph box capex, over(country, label(angle(45)))
graph box profits, over(country, label(angle(45)))
graph box Rdinput, over(country, label(angle(45)))

*scatterplot matrix
graph matrix Rdinput profits capex sales employees, half


******************************************************
*model 
******************************************************

********************baseline did*******************
gen treat=regionbinary
gen post = year>2020
xtreg lnRdinput c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      i.treat##i.post, fe vce(cluster company_id)
	  
* 保存模型结果
eststo baseline

* 导出为 csv 表格
esttab baseline using results_all.csv, ///
    replace se star(* 0.1 ** 0.05 *** 0.01) ///
    label title("Baseline DID Model") ///
    alignment(D) nogaps
	
	
********************Model 2: High Profits as a Mechanism*******************
* Step 1: 计算中位数并保存为标量
summarize L1_profit, detail
scalar med_profit = r(p50)

* Step 2: 用中位数创建 high_profit dummy 变量
gen high_profit = L1_profit > med_profit

xtreg lnRdinput c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      i.treat##i.post##i.high_profit, fe vce(cluster company_id)
	  
eststo highprofit_model

* 导出为 csv 表格
esttab highprofit_model using results_all.csv, ///
    append se star(* 0.1 ** 0.05 *** 0.01) ///
    label title("High profit as Mechanism Model") ///
    alignment(D) nogaps

	
********************Model 3: High capital expenditure as a Mechanism*******************
summarize L1_capex, detail
scalar med_capex = r(p50)
gen high_capex = L1_capex > med_capex

xtreg lnRdinput c.L1_lnsale c.lnemployees c.L1_profit ///
      c.L1_capex c.L1_capex2 i.treat##i.post##i.high_capex, fe vce(cluster company_id)

eststo highcapex_model
	  
* 导出为 csv 表格
esttab highcapex_model using results_all.csv, ///
    append se star(* 0.1 ** 0.05 *** 0.01) ///
    label title("High capital expenditure as Mechanism Model") ///
    alignment(D) nogaps
	
	
********************高员工异质性检验（分组DID）*******************
summarize lnemployees, detail
scalar med_lnemployees = r(p50)
gen high_emp = lnemployees > med_lnemployees

xtreg lnRdinput c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      i.treat##i.post if high_emp==1, fe vce(cluster company_id)
	  
eststo highemp_model  
esttab highemp_model  using results_emp.csv, ///
    replace se star(* 0.1 ** 0.05 *** 0.01) ///
    label title("Heterogenious analysis using number of employees") ///
    alignment(D) nogaps
	
xtreg lnRdinput c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      i.treat##i.post if high_emp==0, fe vce(cluster company_id)
	  
eststo lowemp_model    
esttab lowemp_model using results_emp.csv, ///
    append se star(* 0.1 ** 0.05 *** 0.01) ///
    label title("Heterogenious analysis using number of employees") ///
    alignment(D) nogaps

!mkdir /Users/wanghaoling/Desktop/mypaper/European_Commission/3st_revised/
save "phar1089_dealed.dta", replace


