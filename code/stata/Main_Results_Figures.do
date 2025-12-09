
/**************************************************************************
* Project:    AJAE (2017) Replication Package
* File:       main_results_figures.do
* Purpose:    Generate main figures (Figures 2–5)
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
*   /output/figures

cd "../.."                      // Move to project root relative to code/stata

global DATA    "data"
global OUTPUT  "output"
global FIGS    "$OUTPUT/figures"

capture mkdir "$OUTPUT"
capture mkdir "$FIGS"


/*=======================================================================
   FIGURE 2
   Road / Bridge Density vs Population Density
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Keep one month and two years (2005 & 2010)
keep if Month == 1
keep if year == 2005 | year == 2010

* Scatter bridge density vs population density for selected districts
twoway ///
    (scatter bridge_density pop_area if District == 16, ///
        mlabcolor(navy)   mcolor(navy)   msymbol(X)  ///
        mlabel(year) connect(l) sort yaxis(1)) ///
    (scatter bridge_density pop_area if District == 12, ///
        mlabcolor(black)  mcolor(black)  msymbol(th) ///
        mlabel(year) connect(l) sort yaxis(1)) ///
    (scatter bridge_density pop_area if District == 14, ///
        mlabcolor(blue)   mcolor(green)  msymbol(oh) ///
        mlabel(year) connect(l) sort yaxis(1)) ///
    (lfitci bridge_density pop_area), ///
    name(fig2_bridge_vs_pop, replace) ///
    xtitle("Population density") ///
    ytitle("Bridge density")

graph export "$FIGS/Figure2a_BridgeDensity_vs_PopDensity.png", replace

* Scatter road index density vs population density for same districts
twoway ///
    (scatter roadindex_1_density pop_area if District == 16, ///
        mlabcolor(navy)   mcolor(red)    msymbol(X)  ///
        mlabel(year) connect(l) sort yaxis(1)) ///
    (scatter roadindex_1_density pop_area if District == 12, ///
        mlabcolor(black)  mcolor(blue)   msymbol(th) ///
        mlabel(year) connect(l) sort yaxis(1)) ///
    (scatter roadindex_1_density pop_area if District == 14, ///
        mlabcolor(blue)   mcolor(orange) msymbol(oh) ///
        mlabel(year) connect(l) sort yaxis(1)) ///
    (lfitci roadindex_1_density pop_area), ///
    name(fig2_road_vs_pop, replace) ///
    xtitle("Population density") ///
    ytitle("Road index density")

graph export "$FIGS/Figure2b_RoadIndexDensity_vs_PopDensity.png", replace


/*=======================================================================
   CREATE TIME VARIABLE (MONTHLY)
=======================================================================*/

program define make_monthly_time, rclass
    capture confirm variable mydate
    if _rc {
        gen Months = mod(_n - 1, 12) + 1
        gen mydate = ym(year, Months)
        format mydate %tm
        placevar Months mydate, after(Month)
        drop Months
    }
end

/*=======================================================================
   FIGURE 3
   Jumla Prices – Scatter vs Reference Markets & Time Series
   (District == 12)
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Top row: scatter + fitted lines vs border, regional, central
graph twoway ///
    (scatter local_cr bord_cr if District == 12) ///
    || lfit local_cr bord_cr if District == 12, ///
    fxsize(33.33) fysize(50) ///
    name(jumla_left, replace)

graph twoway ///
    (scatter local_cr reg_cr if District == 12) ///
    || lfit local_cr reg_cr if District == 12, ///
    fxsize(33.33) fysize(50) ///
    name(jumla_center, replace)

graph twoway ///
    (scatter local_cr cent_cr if District == 12) ///
    || lfit local_cr cent_cr if District == 12, ///
    fxsize(33.33) fysize(50) ///
    name(jumla_right, replace)

graph combine jumla_left jumla_center jumla_right, ///
    col(3) name(jumla_top, replace)

* Bottom row: time series of local, regional, border, central prices
quietly make_monthly_time
tsset District mydate, monthly

keep if District == 12

tsline local_cr ///
    || tsline reg_cr ///
    || tsline bord_cr ///
    || tsline cent_cr, ///
    fysize(50) ///
    name(jumla_bottom, replace)

* Combine top and bottom
graph combine jumla_top jumla_bottom, ///
    row(2) name(fig3_jumla, replace)

graph export "$FIGS/Figure3_Jumla_Prices.png", replace


/*=======================================================================
   FIGURE 4
   Kaski Prices – Scatter vs Reference Markets & Time Series
   (District == 14)
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Top row
graph twoway ///
    (scatter local_cr bord_cr if District == 14) ///
    || lfit local_cr bord_cr if District == 14, ///
    fxsize(33.33) fysize(50) ///
    name(kaski_left, replace)

graph twoway ///
    (scatter local_cr reg_cr if District == 14) ///
    || lfit local_cr reg_cr if District == 14, ///
    fxsize(33.33) fysize(50) ///
    name(kaski_center, replace)

graph twoway ///
    (scatter local_cr cent_cr if District == 14) ///
    || lfit local_cr cent_cr if District == 14, ///
    fxsize(33.33) fysize(50) ///
    name(kaski_right, replace)

graph combine kaski_left kaski_center kaski_right, ///
    col(3) name(kaski_top, replace)

* Bottom row: time series
quietly make_monthly_time
tsset District mydate, monthly

keep if District == 14

tsline local_cr ///
    || tsline reg_cr ///
    || tsline bord_cr ///
    || tsline cent_cr, ///
    fysize(50) ///
    name(kaski_bottom, replace)

graph combine kaski_top kaski_bottom, ///
    row(2) name(fig4_kaski, replace)

graph export "$FIGS/Figure4_Kaski_Prices.png", replace


/*=======================================================================
   FIGURE 5
   Mahottari Prices – Scatter vs Reference Markets & Time Series
   (District == 16)
=======================================================================*/

use "$DATA/Nepal_Panel_Foodprice.dta", clear

* Top row
graph twoway ///
    (scatter local_cr bord_cr if District == 16) ///
    || lfit local_cr bord_cr if District == 16, ///
    fxsize(33.33) fysize(50) ///
    name(maho_left, replace)

graph twoway ///
    (scatter local_cr reg_cr if District == 16) ///
    || lfit local_cr reg_cr if District == 16, ///
    fxsize(33.33) fysize(50) ///
    name(maho_center, replace)

graph twoway ///
    (scatter local_cr cent_cr if District == 16) ///
    || lfit local_cr cent_cr if District == 16, ///
    fxsize(33.33) fysize(50) ///
    name(maho_right, replace)

graph combine maho_left maho_center maho_right, ///
    col(3) name(maho_top, replace)

* Bottom row: time series
quietly make_monthly_time
tsset District mydate, monthly

keep if District == 16

tsline local_cr ///
    || tsline reg_cr ///
    || tsline bord_cr ///
    || tsline cent_cr, ///
    fysize(50) ///
    name(maho_bottom, replace)

graph combine maho_top maho_bottom, ///
    row(2) name(fig5_mahottari, replace)

graph export "$FIGS/Figure5_Mahottari_Prices.png", replace


/*=======================================================================
   END OF FILE
=======================================================================*/

display "Main figures (Figures 2–5) generated and exported successfully."






