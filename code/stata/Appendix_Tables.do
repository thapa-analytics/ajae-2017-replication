 
 /**************************************************************************
* Project:    AJAE (2017) Replication Package
* File:       appendix_tables.do
* Purpose:    Create Appendix Tables & Statistical Tests (Tables A2–A7)
** Author:     Ganesh Thapa/Gerald E Shively
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

* Create output folders if needed
capture mkdir "$OUTPUT"
capture mkdir "$TABLES"


/*=======================================================================
   SECTION 1. PANEL DATA PREPARATION
   - Base panel dataset
   - Lagged sample for dynamic models
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

* Panel setup
gen newid = District
tsset newid mydate, monthly

* Save base panel
save "$DATA/Nepal_Panel_Foodprice_1.dta", replace

* Construct lag-based sample
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

generate sample = 1 - missing(l1.lnlocal_cr, l1.lnreg_cr, l1.lncent_cr, l1.lnbord_cr)
keep if sample

* Note: Accounting for lag observations
save "$DATA/Nepal_Panel_Foodprice_lag.dta", replace


/*=======================================================================
   TABLE A3
   Robustness: AGARCH Models for Coarse Rice
=======================================================================*/

*------------------ Model 1 ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

arch lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
     lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr Terai Mountain)

outreg2 using "$TABLES/Appendix_Table_A3_Rice_AGARCH", ///
    word replace label dec(5)
estat ic

*------------------ Model 2 ------------------*
use "$DATA/Nepal_Panel_Foodprice_lag.dta", clear

arch lnlocal_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(roadindex_1_density bridge_density lnreal_fuel_prices Terai Mountain)

outreg2 using "$TABLES/Appendix_Table_A3_Rice_AGARCH", ///
    word append label dec(5)
estat ic

*------------------ Model 3 ------------------*
use "$DATA/Nepal_Panel_Foodprice_lag.dta", clear

regress rice_harv_1 annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
    robust cluster(year)
predict rice_harvest, xb
replace rice_harvest = 0.00001 if rice_harvest <= 0
generate lnrice_harvest = ln(rice_harvest)

arch lnlocal_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain pop1 lnexchangerate lnrice_harvest, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(lnrice_harvest pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A3_Rice_AGARCH", ///
    word append label dec(5)
estat ic

*------------------ Model 4 ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

arch lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
     lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
         Terai Mountain roadindex_1_density bridge_density lnreal_fuel_prices)

outreg2 using "$TABLES/Appendix_Table_A3_Rice_AGARCH", ///
    word append label dec(5)
estat ic

*------------------ Model 5 ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

regress rice_harv_1 annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
    robust cluster(year)
predict rice_harvest, xb
replace rice_harvest = 0.00001 if rice_harvest <= 0
generate lnrice_harvest = ln(rice_harvest)

arch lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
     lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain pop1 lnexchangerate lnrice_harvest, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
         lnrice_harvest pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A3_Rice_AGARCH", ///
    word append label dec(5)
estat ic


/*=======================================================================
   TABLE A4
   Robustness: TGARCH Models for Wheat Flour
=======================================================================*/

*------------------ Model 1 ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

arch lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
     lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         Terai Mountain)

outreg2 using "$TABLES/Appendix_Table_A4_Wheat_TGARCH", ///
    word replace label dec(5)
estat ic

*------------------ Model 2 ------------------*
use "$DATA/Nepal_Panel_Foodprice_lag.dta", clear

arch lnlocal_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(roadindex_1_density bridge_density lnreal_fuel_prices ///
         Terai Mountain)

outreg2 using "$TABLES/Appendix_Table_A4_Wheat_TGARCH", ///
    word append label dec(5)
estat ic

*------------------ Model 3 ------------------*
use "$DATA/Nepal_Panel_Foodprice_lag.dta", clear

regress wheat_harv_1 annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
    robust cluster(year)
predict wheat_harvest
gen lnwheat_harvest = ln(wheat_harvest)
label var lnwheat_harvest "Predicted wheat harvest ('000 MT)"

arch lnlocal_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(lnwheat_harvest pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A4_Wheat_TGARCH", ///
    word append label dec(5)
estat ic

*------------------ Model 4 ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

arch lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
     lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         Terai Mountain roadindex_1_density bridge_density ///
         lnreal_fuel_prices)

outreg2 using "$TABLES/Appendix_Table_A4_Wheat_TGARCH", ///
    word append label dec(5)
estat ic

*------------------ Model 5 ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

regress wheat_harv_1 annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
    robust cluster(year)
predict wheat_harvest
gen lnwheat_harvest = ln(wheat_harvest)
label var lnwheat_harvest "Predicted wheat harvest ('000 MT)"

arch lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
     lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         lnwheat_harvest pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A4_Wheat_TGARCH", ///
    word append label dec(5)
estat ic


/*=======================================================================
   TABLE A5
   Robustness: Single-Market Specifications (Rice & Wheat)
=======================================================================*/

*------------------ Coarse Rice: Regional Only ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

regress rice_harv_1 annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
    robust cluster(year)
predict rice_harvest, xb
replace rice_harvest = 0.00001 if rice_harvest <= 0
generate lnrice_harvest = ln(rice_harvest)

arch lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnreg_cr lnrice_harvest Terai Mountain ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A5_Rice_Wheat_MarketSubset", ///
    word replace label dec(5)
estat ic

*------------------ Coarse Rice: Central Only ------------------*
arch lnlocal_cr month_time_trend l1.lnlocal_cr lncent_cr l1.lncent_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lncent_cr lnrice_harvest Terai Mountain ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A5_Rice_Wheat_MarketSubset", ///
    word append label dec(5)
estat ic

*------------------ Coarse Rice: Border Only ------------------*
arch lnlocal_cr month_time_trend l1.lnlocal_cr lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnbord_cr lnrice_harvest Terai Mountain ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A5_Rice_Wheat_MarketSubset", ///
    word append label dec(5)
estat ic

*------------------ Wheat Flour: Regional Only ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

regress wheat_harv_1 annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
    robust cluster(year)
predict wheat_harvest
gen lnwheat_harvest = ln(wheat_harvest)
label var lnwheat_harvest "Predicted wheat harvest ('000 MT)"

arch lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnreg_wf lnwheat_harvest Terai Mountain ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A5_Rice_Wheat_MarketSubset", ///
    word append label dec(5)
estat ic

*------------------ Wheat Flour: Central Only ------------------*
arch lnlocal_wf month_time_trend l1.lnlocal_wf lncent_wf l1.lncent_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lncent_wf lnwheat_harvest Terai Mountain ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A5_Rice_Wheat_MarketSubset", ///
    word append label dec(5)
estat ic

*------------------ Wheat Flour: Border Only ------------------*
arch lnlocal_wf month_time_trend l1.lnlocal_wf lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain ///
     roadindex_1_density bridge_density ///
     mount_road mount_bridge terai_road terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnbord_wf lnwheat_harvest Terai Mountain ///
         roadindex_1_density bridge_density lnreal_fuel_prices ///
         pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A5_Rice_Wheat_MarketSubset", ///
    word append label dec(5)
estat ic


/*=======================================================================
   TABLE A7
   Robustness: Alternative Road Index Weights
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

* Road indices
gen roadindex_1   = black_pitched + gravel*0.05 + earthern*0.0166
gen rdindex_1_dens = roadindex_1 / district_area

gen roadindex_2   = black_pitched + gravel*0.1 + earthern*0.025
gen rdindex_2_dens = roadindex_2 / district_area

* Interaction terms
gen mount_road_1 = Mountain * rdindex_1_dens
gen terai_road_1 = Terai    * rdindex_1_dens

gen mount_road_2 = Mountain * rdindex_2_dens
gen terai_road_2 = Terai    * rdindex_2_dens

*------------------ Coarse Rice: 1–20–60 ------------------*
regress rice_harv_1 annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
    robust cluster(year)
predict rice_harvest, xb
replace rice_harvest = 0.00001 if rice_harvest <= 0
generate lnrice_harvest = ln(rice_harvest)

arch lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
     lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain rdindex_1_dens bridge_density ///
     mount_road_1 mount_bridge terai_road_1 terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
         lnrice_harvest Terai Mountain rdindex_1_dens bridge_density ///
         lnreal_fuel_prices pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A7_Alt_RoadIndex", ///
    word replace label dec(5)
estat ic

*------------------ Coarse Rice: 1–10–40 ------------------*
arch lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
     lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain rdindex_2_dens bridge_density ///
     mount_road_2 mount_bridge terai_road_2 terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
     arch(1/1) garch(1/1) saarch(1/1) ///
     het(month_time_trend l1.lnreg_cr l1.lncent_cr l1.lnbord_cr ///
         lnrice_harvest Terai Mountain rdindex_2_dens bridge_density ///
         lnreal_fuel_prices pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A7_Alt_RoadIndex", ///
    word append label dec(5)
estat ic

*------------------ Wheat Flour: 1–20–60 ------------------*
regress wheat_harv_1 annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
    robust cluster(year)
predict wheat_harvest
gen lnwheat_harvest = ln(wheat_harvest)
label var lnwheat_harvest "Predicted wheat harvest ('000 MT)"

arch lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
     lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain rdindex_1_dens bridge_density ///
     mount_road_1 mount_bridge terai_road_1 terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         lnwheat_harvest Terai Mountain rdindex_1_dens ///
         bridge_density lnreal_fuel_prices pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A7_Alt_RoadIndex", ///
    word append label dec(5)
estat ic

*------------------ Wheat Flour: 1–10–40 ------------------*
arch lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
     lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
     April Aug Dec Feb Jan July June Sept March Nov Oct ///
     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
     Terai Mountain rdindex_2_dens bridge_density ///
     mount_road_2 mount_bridge terai_road_2 terai_bridge ///
     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, ///
     arch(1/1) garch(1/1) tarch(1/1) ///
     het(month_time_trend l1.lnreg_wf l1.lncent_wf l1.lnbord_wf ///
         lnwheat_harvest Terai Mountain rdindex_2_dens ///
         bridge_density lnreal_fuel_prices pop1 lnexchangerate)

outreg2 using "$TABLES/Appendix_Table_A7_Alt_RoadIndex", ///
    word append label dec(5)
estat ic


/*=======================================================================
   TABLE A6 & OTHER DIAGNOSTIC TESTS
   - Multicollinearity (VIF)
   - Cross-sectional dependence
   - Panel autocorrelation & ARCH
=======================================================================*/

*------------------ VIF: Coarse Rice ------------------*
regress lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
        lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
        April Aug Dec Feb Jan July June Sept March Nov Oct ///
        Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
        Terai Mountain ///
        roadindex_1_density bridge_density ///
        mount_road mount_bridge terai_road terai_bridge ///
        lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, robust

estat vif

*------------------ VIF: Wheat Flour ------------------*
use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

regress wheat_harv_1 annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
    robust cluster(year)
predict wheat_harvest
gen lnwheat_harvest = ln(wheat_harvest)
label var lnwheat_harvest "Predicted wheat harvest ('000 MT)"

reg lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
    lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
    April Aug Dec Feb Jan July June Sept March Nov Oct ///
    Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
    Terai Mountain ///
    roadindex_1_density bridge_density ///
    mount_road mount_bridge terai_road terai_bridge ///
    lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, robust

estat vif


/***********************************************************************
   Miscellaneous Statistical Tests (Cross-Sectional Dependence, etc.)
***********************************************************************/

use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

regress rice_harv_1 annual_trend Terai Mountain rice_area_1 monsoon_rice, ///
    robust cluster(year)
predict rice_harvest, xb
replace rice_harvest = 0.00001 if rice_harvest <= 0
generate lnrice_harvest = ln(rice_harvest)

* Pearson test of cross-sectional dependence (Pesaran)
quietly xtreg lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
               lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
               April Aug Dec Feb Jan July June Sept March Nov Oct ///
               Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
               Terai Mountain ///
               roadindex_1_density bridge_density ///
               mount_road mount_bridge terai_road terai_bridge ///
               lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, fe

xtcsd, pesaran abs

* Breusch–Pagan LM test for cross-sectional correlation
xttest2

* Driscoll–Kraay standard errors (xtpcse)
xtpcse lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
       lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
       April Aug Dec Feb Jan July June Sept March Nov Oct ///
       Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
       Terai Mountain ///
       roadindex_1_density bridge_density ///
       mount_road mount_bridge terai_road terai_bridge ///
       lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
       correlation(psar1)

* xtscc (Beck–Katz with Driscoll–Kraay)
xtreg lnlocal_cr month_time_trend l1.lnlocal_cr lnreg_cr l1.lnreg_cr ///
      lncent_cr l1.lncent_cr lnbord_cr l1.lnbord_cr ///
      April Aug Dec Feb Jan July June Sept March Nov Oct ///
      Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
      Terai Mountain ///
      roadindex_1_density bridge_density ///
      mount_road mount_bridge terai_road terai_bridge ///
      lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, robust

* Create explicit lag variables for xtscc
gen l1_lnlocal_cr = l1.lnlocal_cr
gen l1_lnreg_cr   = l1.lnreg_cr
gen l1_lncent_cr  = l1.lncent_cr
gen l1_lnbord_cr  = l1.lnbord_cr

xtscc lnlocal_cr month_time_trend l1_lnlocal_cr lnreg_cr l1_lnreg_cr ///
      lncent_cr l1_lncent_cr lnbord_cr l1_lnbord_cr ///
      April Aug Dec Feb Jan July June Sept March Nov Oct ///
      Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
      Terai Mountain ///
      mount_road mount_bridge terai_road terai_bridge ///
      roadindex_1_density bridge_density ///
      lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, ///
      fe lag(1)

xtreg lnlocal_cr month_time_trend l1_lnlocal_cr lnreg_cr l1_lnreg_cr ///
      lncent_cr l1_lncent_cr lnbord_cr l1_lnbord_cr ///
      April Aug Dec Feb Jan July June Sept March Nov Oct ///
      Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
      roadindex_1_density bridge_density ///
      lnreal_fuel_prices pop1 lnexchangerate lnrice_harvest, fe

* Long-run market integration hypothesis: Coarse Rice
test l1.lnlocal_cr + lnreg_cr + l1.lnreg_cr + ///
     l1.lncent_cr + lncent_cr + l1.lnbord_cr + lnbord_cr = 1

* ARCH–LM test (Coarse Rice)
predict residc, residuals
gen resquc = residc^2
regress resquc month_time_trend l1.resquc

* Wooldridge test for autocorrelation (Coarse Rice)
xtserial lnlocal_cr month_time_trend lnreg_cr lncent_cr lnbord_cr ///
         roadindex_1_density lnreal_fuel_prices pop1 lnexchangerate ///
         lnrice_harvest, output


/***********************************************************************
   Wheat Flour Diagnostics
***********************************************************************/

use "$DATA/Nepal_Panel_Foodprice_1.dta", clear

regress wheat_harv_1 annual_trend Terai Mountain wheat_area_1 rainfall_wheat, ///
    robust cluster(year)
predict wheat_harvest
gen lnwheat_harvest = ln(wheat_harvest)
label var lnwheat_harvest "Predicted wheat harvest ('000 MT)"

quietly xtreg lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
                     lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
                     April Aug Dec Feb Jan July June Sept March Nov Oct ///
                     Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
                     Terai Mountain ///
                     roadindex_1_density bridge_density ///
                     mount_road mount_bridge terai_road terai_bridge ///
                     lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, robust

xtcsd, pesaran abs

* Wooldridge test for autocorrelation (Wheat)
xtserial lnlocal_wf month_time_trend lnreg_wf lncent_wf lnbord_wf ///
         roadindex_1_density lnreal_fuel_prices pop1 lnexchangerate ///
         lnrice_harvest, output

* Main Wheat Regression (for reporting)
reg lnlocal_wf month_time_trend l1.lnlocal_wf lnreg_wf l1.lnreg_wf ///
    lncent_wf l1.lncent_wf lnbord_wf l1.lnbord_wf ///
    April Aug Dec Feb Jan July June Sept March Nov Oct ///
    Year1 Year2 Year3 Year4 Year5 Year6 Year7 Year8 ///
    Terai Mountain ///
    roadindex_1_density bridge_density ///
    mount_road mount_bridge terai_road terai_bridge ///
    lnreal_fuel_prices pop1 lnexchangerate lnwheat_harvest, robust

outreg2 using "$TABLES/Misc_Wheat_Regression", ///
    word replace label dec(5)
estat ic

* Long-run market integration hypothesis: Wheat Flour
test l1.lnlocal_wf + lnreg_wf + l1.lnreg_wf + ///
     l1.lncent_wf + lncent_wf + l1.lnbord_wf + lnbord_wf = 1

* ARCH–LM test (Wheat Flour)
predict residw, residuals
gen resquw = residw^2
regress resquw month_time_trend l1.resquw


/*=======================================================================
   TABLE A2
   Correlation Matrix for Cereal & Potato Prices
=======================================================================*/

use "$DATA/corr_cere_potato.dta", clear

pwcorr coarse_rice medium_rice fine_rice wheat_flour ///
       red_potato white_potato, ///
       star(.01) bonferroni

mkcorr coarse_rice medium_rice fine_rice wheat_flour ///
       red_potato white_potato, ///
       log("$TABLES/Appendix_Table_A2_Correlation") ///
       replace label sig mdec(2) casewise


/*=======================================================================
   END OF FILE
=======================================================================*/

display "All Appendix Tables and statistical tests successfully generated."

 
 