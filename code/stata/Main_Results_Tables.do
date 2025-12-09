/**************************************************************************
* Project:    AJAE (2017) Replication Package
* File:       main_results_tables.do
* Purpose:    Generate main results tables (Tables 1–5)
*
* Author:     Ganesh Thapa
* Date:       [add date]
**************************************************************************/

clear all
set more off

/*=======================================================================
   PATH SETUP
=======================================================================*/
* Assumes project root structure:
*   /data
*   /code/stata
*   /output/tables

cd "../.."                      // Move to project root relative to code/stata

global DATA    "data"
global OUTPUT  "output"
global TABLES  "$OUTPUT/tables"

capture mkdir "$OUTPUT"
capture mkdir "$TABLES"


/*=======================================================================
   TABLE 1
   Descriptive Statistics
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Rice-related variables
summarize ///
    rice_harv_1 rice_area_1 monsoon_rice ///
    Terai Mountain ///
    local_cr reg_cr cent_cr bord_cr ///
    roadindex_1_density bridge_density ///
    real_fuel_prices exchangerate

* Wheat-related variables
summarize ///
    wheat_harv_1 wheat_area_1 rainfall_wheat ///
    Terai Mountain Hill ///
    local_wf reg_wf cent_wf bord_wf ///
    roadindex_1_density bridge_density ///
    real_fuel_prices exchangerate


/*=======================================================================
   TABLE 2
   Agricultural Production Function Regressions
   (Rice & Wheat Harvest)
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

keep if Month == 1     // Drop duplicate observations

regress rice_harv_1 ///
        annual_trend Terai Mountain rice_area_1 monsoon_rice, robust
outreg2 using "$TABLES/Main_Table2_Harvest_Production", ///
    word replace label dec(5)

regress wheat_harv_1 ///
        annual_trend Terai Mountain wheat_area_1 rainfall_wheat, robust
outreg2 using "$TABLES/Main_Table2_Harvest_Production", ///
    word append label dec(5)


/*=======================================================================
   TABLE 3
   Panel Setup & Breitung Unit Root Tests
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Log transformations
foreach v in local_cr reg_cr cent_cr bord_cr ///
             local_wf reg_wf cent_wf bord_wf ///
             population real_fuel_prices exchangerate {
    gen ln`v' = ln(`v')
}

* Monthly date variable
gen Months = mod(_n - 1, 12) + 1
gen mydate = ym(year, Months)
format mydate %tm
placevar Months mydate, after(Month)
drop Months

* Panel ID
gen newid = District
tsset newid mydate, monthly

* Breitung panel unit root tests (robust where specified)
xtunitroot breitung lnlocal_cr,       robust lags(1)
xtunitroot breitung lnreg_cr,         robust lags(1)
xtunitroot breitung lncent_cr,        robust lags(1)
xtunitroot breitung lnbord_cr,        robust lags(1)
xtunitroot breitung lnlocal_wf,       robust lags(1)
xtunitroot breitung lnreg_wf,         robust lags(1)
xtunitroot breitung lncent_wf,        robust lags(1)
xtunitroot breitung lnbord_wf,        robust lags(1)
xtunitroot breitung lnexchangerate,          lags(1)
xtunitroot breitung lnreal_fuel_prices,      lags(1)


/*=======================================================================
   TABLE 4
   Coarse Rice Regression Results (Main Models)
   AR(1), ARCH, GARCH, AGARCH
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Log transformations
foreach v in local_cr reg_cr cent_cr bord_cr ///
             population real_fuel_prices exchangerate {
    gen ln`v' = ln(`v')
}

gen lnpop = ln(population)
gen pop1  = population / district_area

* Year dummies
tabulate year, generate(Year)

* District dummies
tabulate District, generate(district)

* Monthly date variable
gen Months = mod(_n - 1, 12) + 1
gen mydate = ym(year, Months)
format mydate %tm
placevar Months mydate, after(Month)
drop Months

* Panel ID
gen newid = District
tsset newid mydate, monthly

* Production equation for rice harvest
regress rice_harv_1 ///
        annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
        robust cluster(year)
predict rice_harvest, xb
replace rice_harvest = 0.00001 if rice_harvest <= 0
gen lnrice_harvest = ln(rice_harvest)

*------------------ AR(1) Model ------------------*
regress lnlocal_cr month_time_trend l1.lnlocal_cr ///
        lnreg_cr  l1.lnreg_cr ///
        lncent_cr l1.lncent_cr ///
        lnbord_cr l1.lnbord_cr ///
        April Aug Dec Feb Jan July June Sept March Nov Oct ///
        Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
        roadindex_1_density bridge_density ///
        mount_road mount_bridge terai_road terai_bridge ///
        lnreal_fuel_prices pop1 lnrice_harvest lnexchangerate ///
        Terai Mountain, robust

outreg2 using "$TABLES/Main_Table4_Rice_Main", ///
    word replace label dec(5)
estat ic

*------------------ ARCH(1) Model ------------------*
arch lnlocal_cr month_time_trend l1.lnlocal_cr ///
     lnreg_cr  l1.lnreg_cr ///
     lncent_cr l1.lncent_cr ///
     lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnrice_harvest lnexchangerate ///
     Terai Mountain, ///
     arch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnrice_harvest lnexchangerate Terai Mountain) ///
     vce(robust)

outreg2 using "$TABLES/Main_Table4_Rice_Main", ///
    word append label dec(5)
estat ic

*------------------ GARCH(1,1) Model ------------------*
arch lnlocal_cr month_time_trend l1.lnlocal_cr ///
     lnreg_cr  l1.lnreg_cr ///
     lncent_cr l1.lncent_cr ///
     lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnrice_harvest lnexchangerate ///
     Terai Mountain, ///
     arch(1/1) garch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnrice_harvest lnexchangerate Terai Mountain) ///
     vce(robust)

outreg2 using "$TABLES/Main_Table4_Rice_Main", ///
    word append label dec(5)
estat ic

*------------------ AGARCH(1,1) Model ------------------*
arch lnlocal_cr month_time_trend l1.lnlocal_cr ///
     lnreg_cr  l1.lnreg_cr ///
     lncent_cr l1.lncent_cr ///
     lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnrice_harvest lnexchangerate ///
     Terai Mountain, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnrice_harvest lnexchangerate Terai Mountain) ///
     vce(robust)

outreg2 using "$TABLES/Main_Table4_Rice_Main", ///
    word append label dec(5)
estat ic


/*=======================================================================
   TABLE 5
   Wheat Flour Regression Results (Main Models)
   AR(1), ARCH, GARCH, TGARCH
=======================================================================*/

* Production equation for wheat harvest
regress wheat_harv_1 ///
        annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
        robust cluster(year)

gen lnwheat_harvest = ln(wheat_harvest)
label var lnwheat_harvest "Predicted wheat harvest ('000 MT)"

*------------------ AR(1) Model ------------------*
reg lnlocal_wf month_time_trend l1.lnlocal_wf ///
    lnreg_wf  l1.lnreg_wf ///
    lncent_wf l1.lncent_wf ///
    lnbord_wf l1.lnbord_wf ///
    April Aug Dec Feb Jan July June Sept March Nov Oct ///
    Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
    Terai Mountain ///
    roadindex_1_density bridge_density ///
    mount_road mount_bridge terai_road terai_bridge ///
    lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, robust

outreg2 using "$TABLES/Main_Table5_Wheat_Main", ///
    word replace label dec(5)
estat ic

*------------------ ARCH(1) Model ------------------*
arch lnlocal_wf month_time_trend l1.lnlocal_wf ///
     lnreg_wf  l1.lnreg_wf ///
     lncent_wf l1.lncent_wf ///
     lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         lnwheat_harvest Terai Mountain roadindex_1_density ///
         bridge_density lnreal_fuel_prices pop1 lnexchangerate) ///
     vce(robust)

outreg2 using "$TABLES/Main_Table5_Wheat_Main", ///
    word append label dec(5)
estat ic

*------------------ GARCH(1,1) Model ------------------*
arch lnlocal_wf month_time_trend l1.lnlocal_wf ///
     lnreg_wf  l1.lnreg_wf ///
     lncent_wf l1.lncent_wf ///
     lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         lnwheat_harvest Terai Mountain roadindex_1_density ///
         bridge_density lnreal_fuel_prices pop1 lnexchangerate) ///
     vce(robust)

outreg2 using "$TABLES/Main_Table5_Wheat_Main", ///
    word append label dec(5)
estat ic

*------------------ TGARCH(1,1) Model ------------------*
arch lnlocal_wf month_time_trend l1.lnlocal_wf ///
     lnreg_wf  l1.lnreg_wf ///
     lncent_wf l1.lncent_wf ///
     lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         lnwheat_harvest Terai Mountain roadindex_1_density ///
         bridge_density lnreal_fuel_prices pop1 lnexchangerate)

outreg2 using "$TABLES/Main_Table5_Wheat_Main", ///
    word append label dec(5)
estat ic

/*=======================================================================
   END OF FILE
=======================================================================*/

display "Main results tables (Tables 1–5) generated successfully."
