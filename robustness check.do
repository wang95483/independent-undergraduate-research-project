*robustness check
cd "/Users/wanghaoling/Desktop/mypaper/European_Commission/3st_revised"
use "/Users/wanghaoling/Desktop/mypaper/European_Commission/3st_revised/phar1089_dealed.dta"

*command installment
ssc install estout
ssc install outreg2
ssc install coefplot
ssc install reghdfe, replace
ssc install ftools, replace
ssc install moremata, replace

*----------------------------------------------------
*graph test
collapse lnRdinput, by(year treat)
keep if year <= 2019
twoway (line lnRdinput year if treat==1, lcolor(blue)) ///
       (line lnRdinput year if treat==0, lcolor(red)), ///
       legend(label(1 "China") label(2 "EU")) ///
       title("Pre-Trend Check: ln(R&D Investment)")
clear
use "/Users/wanghaoling/Desktop/mypaper/European_Commission/3st_revised/phar1089_dealed.dta"
*----------------------------------------------------
*Event-study Dynamic Effect Specification
* Step 1: Create event time indicators
gen event_time = year - 2020

* Step 2: Create a set of dummy variables for event time, omitting one as baseline
tab event_time, gen(event)

gen event_grp = .

replace event_grp = 1 if event_time == -5
replace event_grp = 2 if event_time == -4
replace event_grp = 3 if event_time == -3
replace event_grp = 4 if event_time == -2
replace event_grp = 5 if event_time == -1
replace event_grp = 6 if event_time == 0   // base year, omitted
replace event_grp = 7 if event_time == 1
replace event_grp = 8 if event_time == 2
replace event_grp = 9 if event_time == 3
replace event_grp = 10 if event_time == 4

* Step 3: Run event-study regression using i.event_time#treat interacted with treatment
xtreg lnRdinput i.event_grp##i.treat c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      , fe vce(cluster company_id)
	  
outreg2 using para_result.doc, replace ctitle("Event-study Dynamic Effects") dec(3) addstat(Observations, e(N))

***********bootstrapped standard error **********************
* Step 1: Run event-study regression using xtreg (without bootstrapping)
xtreg lnRdinput i.event_grp##i.treat c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      , fe vce(cluster company_id)

* Step 2: Use bootstrap to get standard errors
bootstrap, reps(1000): xtreg lnRdinput i.event_grp##i.treat c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 
outreg2 using bootstrap_result.doc, replace ctitle("Event-study Dynamic Effects (bootstrapped standard error)") dec(3) addstat(Observations, e(N))
**************************************************************

* Step 4: Graph1 event-study coefficients
* You may want to manually estimate with margins and then graph:
margins, dydx(treat) over(event_grp) level(95)
marginsplot, ///
    title("Dynamic Treatment Effects") ///
    yline(0) ///
    xlabel(2 "2016" 3 "2017" 4 "2018" 5 "2019" 6 "2020" 7 "2021" 8 "2022" 9 "2023" 10 "2024")
	
	
*Wald test
testparm 1.treat#1.event_grp 1.treat#2.event_grp 1.treat#3.event_grp 1.treat#4.event_grp 1.treat#5.event_grp 1.treat#6.event_grp
testparm 1.treat#1.event_grp 1.treat#2.event_grp 1.treat#3.event_grp 


* Step 4: grph 2 Plot event study 这张图目前没有出现在论文里
margins i.event_grp#i.treat
marginsplot, title("Event Study: Dynamic Treatment Effects") ///
    yline(0, lpattern(dash)) legend(pos(6)) ///
    recastci(rarea) recast(line)
*----------------------------------------------------
*placebo test (regression)
gen placebo_post = year >= 2017 & year <= 2018
keep if inrange(year, 2015, 2018)
xtreg lnRdinput c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      treat##placebo_post, fe vce(cluster company_id)
* 保存为 Word
outreg2 using placebo_result.doc, replace ctitle("Placebo Test (2018)") dec(3) addstat(Observations, e(N))

clear
use "/Users/wanghaoling/Desktop/mypaper/European_Commission/3st_revised/phar1089_dealed.dta"
* 设定参考年为 2018 （placebo 处理年）
gen rel_year = year - 2018

* 保留2015–2018年数据
keep if inrange(year, 2015, 2018)

* 生成虚拟变量 D_m1, D_m2, D_m3 （对应 2017, 2016, 2015）
forvalues i = 1/3 {
    local yr = -1 * `i'
    gen D_m`i' = (rel_year == `yr') * treat
}

* 回归
eststo placebo: xtreg lnRdinput D_m3 D_m2 D_m1 ///
    c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2, ///
    fe vce(cluster company_id)

* 作图
coefplot placebo, keep(D_m3 D_m2 D_m1) ///
    xlabel(1 "Year = 2015" 2 "Year = 2016" 3 "Year = 2017") ///
    title("Placebo Test (Coefficient Plot)") ///
    xtitle("Placebo Treatment Year") ///
    ytitle("Estimated Coefficient (ln(R&D Investment))") ///
    vertical ///
    ciopts(recast(rcap) lcolor(gs8)) msymbol(O) mcolor(black)

*----------------------------------------------------
*an alternative dependent variable specification
gen Rdintensity=Rdinput/sales
gen lnRdintensity = ln(Rdintensity)

xtreg lnRdintensity c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      i.treat##i.post, fe vce(cluster company_id)
	  
outreg2 using lnRdintensity_result.doc, replace ctitle("Regression of ln(R&D Intensity) conducting by sales on Treatment")

	
gen Rdintensity_emp=Rdinput/employees
gen lnRdintensity_emp = ln(Rdintensity_emp)
xtreg lnRdintensity_emp c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
      i.treat##i.post, fe vce(cluster company_id)
	  
outreg2 using lnRdintensity_result.doc, append ctitle("Regression of ln(R&D Intensity) conducting by employees on Treatment")

*a clustering robustness test
reghdfe lnRdinput c.L1_lnsale c.lnemployees c.L1_profit c.L1_capex c.L1_capex2 ///
        i.treat##i.post, absorb(company_id year) vce(cluster company_id year)
		
outreg2 using clustering_robustness.doc, replace ///		
ctitle("Clustering Robustness Test with Two-Way Clustering at Firm and Year Level") ///
dec(3) addnote("Standard errors are clustered at both firm and year levels. The results remain robust, though standard errors may be inflated due to a small number of clusters.")



