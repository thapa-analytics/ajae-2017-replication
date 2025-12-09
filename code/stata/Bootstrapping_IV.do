/**************************************************************************
* Project:    AJAE (2017) Replication Package
* File:       bootstrap_se.do
* Purpose:    Bootstrap standard errors for rice & wheat models
* Author:     Ganesh Thapa/Gerald E Shively
**************************************************************************/

clear all
set more off

/*=======================================================================
   PATH SETUP
=======================================================================*/
* Assumes project root structure:
*   /data
*   /code/stata
*   /output (optional, if you later want to save results)

cd "../.."                      // Move to project root relative to code/stata

global DATA    "data"
global OUTPUT  "output"

capture mkdir "$OUTPUT"


/*=======================================================================
   DATA PREPARATION
   - Base panel structure
   - Logs & sample restriction for lagged models
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Log transforms
foreach v in local_cr reg_cr cent_cr bord_cr ///
             local_wf reg_wf cent_wf bord_wf ///
             population real_fuel_prices exchangerate {
    gen ln`v' = ln(`v')
}

gen lnpop = ln(population)
gen pop1  = population / district_area

* Year dummies
tabulate year, generate(Year)

* District dummies
tabulate District, generate(district)

* Monthly time variable
gen Months = mod(_n - 1, 12) + 1
gen mydate = ym(year, Months)
format mydate %tm
placevar Months mydate, after(Month)
drop Months

* Panel ID
gen newid = District
tsset newid mydate, monthly

* Sample restriction for lag structure
gen sample = 1 - missing(l1.lnlocal_cr, l1.lnreg_cr, l1.lncent_cr, l1.lnbord_cr)
keep if sample


/*=======================================================================
   RICE MODELS – BOOTSTRAP
   AR(1), ARCH, GARCH, AGARCH
=======================================================================*/

*------------------ AR(1): Rice ------------------*
capture program drop harvest_inst
program define harvest_inst, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnrice_harvest

    regress rice_harv_1 ///
            annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnrice_harvest = ln(`xb')

    regress lnlocal_cr month_time_trend l1.lnlocal_cr ///
            lnreg_cr  l1.lnreg_cr ///
            lncent_cr l1.lncent_cr ///
            lnbord_cr l1.lnbord_cr ///
            April Aug Dec Feb Jan July June Sept March Nov Oct ///
            Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
            Terai Mountain ///
            roadindex_1_density bridge_density ///
            mount_road mount_bridge terai_road terai_bridge ///
            lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, robust

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap _b[lnrice_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst


*------------------ ARCH(1): Rice ------------------*
capture program drop harvest_inst
program define harvest_inst, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnrice_harvest

    regress rice_harv_1 ///
            annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnrice_harvest = ln(`xb')

    arch lnlocal_cr month_time_trend l1.lnlocal_cr ///
         lnreg_cr  l1.lnreg_cr ///
         lncent_cr l1.lncent_cr ///
         lnbord_cr l1.lnbord_cr ///
         April Aug Dec Feb Jan July June Sept March Nov Oct ///
         Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
         Terai Mountain ///
         roadindex_1_density bridge_density ///
         mount_road mount_bridge terai_road terai_bridge ///
         lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
         arch(1/1) ///
         het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
             lnrice_harvest Terai Mountain ///
             roadindex_1_density bridge_density ///
             lnreal_fuel_prices pop1 lnexchangerate)

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap [lnlocal_cr]_b[lnrice_harvest] [HET]_b[lnrice_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst


*------------------ GARCH(1,1): Rice ------------------*
capture program drop harvest_inst
program define harvest_inst, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnrice_harvest

    regress rice_harv_1 ///
            annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnrice_harvest = ln(`xb')

    arch lnlocal_cr month_time_trend l1.lnlocal_cr ///
         lnreg_cr  l1.lnreg_cr ///
         lncent_cr l1.lncent_cr ///
         lnbord_cr l1.lnbord_cr ///
         April Aug Dec Feb Jan July June Sept March Nov Oct ///
         Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
         Terai Mountain ///
         roadindex_1_density bridge_density ///
         mount_road mount_bridge terai_road terai_bridge ///
         lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
         arch(1/1) garch(1/1) ///
         het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
             lnrice_harvest Terai Mountain ///
             roadindex_1_density bridge_density ///
             lnreal_fuel_prices pop1 lnexchangerate)

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap [lnlocal_cr]_b[lnrice_harvest] [HET]_b[lnrice_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst


*------------------ AGARCH(1,1): Rice ------------------*
capture program drop harvest_inst
program define harvest_inst, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnrice_harvest

    regress rice_harv_1 ///
            annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnrice_harvest = ln(`xb')

    arch lnlocal_cr month_time_trend l1.lnlocal_cr ///
         lnreg_cr  l1.lnreg_cr ///
         lncent_cr l1.lncent_cr ///
         lnbord_cr l1.lnbord_cr ///
         April Aug Dec Feb Jan July June Sept March Nov Oct ///
         Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
         Terai Mountain ///
         roadindex_1_density bridge_density ///
         mount_road mount_bridge terai_road terai_bridge ///
         lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
         arch(1/1) garch(1/1) saarch(1/1) ///
         het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
             lnrice_harvest Terai Mountain ///
             roadindex_1_density bridge_density ///
             lnreal_fuel_prices pop1 lnexchangerate)

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap [lnlocal_cr]_b[lnrice_harvest] [HET]_b[lnrice_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst


/*=======================================================================
   WHEAT MODELS – BOOTSTRAP
   AR(1), ARCH, GARCH, TGARCH
=======================================================================*/

*------------------ AR(1): Wheat ------------------*
capture program drop harvest_inst_wheat
program define harvest_inst_wheat, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnwheat_harvest

    regress wheat_harv_1 ///
            annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnwheat_harvest = ln(`xb')

    regress lnlocal_wf month_time_trend l1.lnlocal_wf ///
            lnreg_wf  l1.lnreg_wf ///
            lncent_wf l1.lncent_wf ///
            lnbord_wf l1.lnbord_wf ///
            April Aug Dec Feb Jan July June Sept March Nov Oct ///
            Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
            Terai Mountain ///
            roadindex_1_density bridge_density ///
            mount_road mount_bridge terai_road terai_bridge ///
            lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, robust

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap _b[lnwheat_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst_wheat


*------------------ ARCH(1): Wheat ------------------*
capture program drop harvest_inst_wheat_1
program define harvest_inst_wheat_1, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnwheat_harvest

    regress wheat_harv_1 ///
            annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnwheat_harvest = ln(`xb')

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
             bridge_density lnreal_fuel_prices pop1 lnexchangerate)

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap [lnlocal_wf]_b[lnwheat_harvest] [HET]_b[lnwheat_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst_wheat_1


*------------------ GARCH(1,1): Wheat ------------------*
capture program drop harvest_inst_wheat_1
program define harvest_inst_wheat_1, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnwheat_harvest

    regress wheat_harv_1 ///
            annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnwheat_harvest = ln(`xb')

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
             bridge_density lnreal_fuel_prices pop1 lnexchangerate)

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap [lnlocal_wf]_b[lnwheat_harvest] [HET]_b[lnwheat_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst_wheat_1


*------------------ TGARCH(1,1): Wheat ------------------*
capture program drop harvest_inst_wheat_1
program define harvest_inst_wheat_1, eclass
    version 13
    tempname b
    tempvar xb
    capture drop lnwheat_harvest

    regress wheat_harv_1 ///
            annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
            robust cluster(year)
    predict `xb', xb
    replace `xb' = 0.00001 if `xb' <= 0
    generate lnwheat_harvest = ln(`xb')

    arch lnlocal_wf month_time_trend l1.lnlocal_wf ///
         lnreg_wf  l1.lnreg_wf ///
         lncent_wf l1.lncent_wf ///
         lnbord_wf l1.lnbord_wf ///
         April Aug Dec Feb Jan July June Sept March Nov Oct ///
         Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
         roadindex_1_density bridge_density ///
         mount_road mount_bridge terai_road terai_bridge ///
         lnreal_fuel_prices pop1 lnwheat_harvest lnexchangerate ///
         Terai Mountain, ///
         arch(1/1) garch(1/1) tarch(1/1) ///
         het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
             roadindex_1_density bridge_density lnreal_fuel_prices ///
             pop1 lnexchangerate lnwheat_harvest Terai Mountain)

    matrix `b' = e(b)
    ereturn post `b'
end

bootstrap [lnlocal_wf]_b[lnwheat_harvest] [HET]_b[lnwheat_harvest], ///
    reps(50) seed(123) ///
    cluster(District) idcluster(newid) nowarn: ///
    harvest_inst_wheat_1


/*=======================================================================
   END OF FILE
=======================================================================*/

display "Bootstrap standard error routines completed for rice and wheat."
