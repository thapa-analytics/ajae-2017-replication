/**************************************************************************
* Project:    AJAE (2017) Replication Package
* File:       appendix_figures.do
* Purpose:    Create all Appendix Figures (Figures A1–A6)
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
*   /output/figures

cd "../.."                      // Move to project root relative to code/stata
global DATA    "data"
global OUTPUT  "output/figures"

/*=======================================================================
   FIGURE A1
   Road length trends for Jumla, Kaski, and Mahottari
=======================================================================*/

use "$DATA/graph_roadlength.dta", clear

line ///
    totroad_length_kaski ///
    totroad_length_jumla ///
    totroad_length_mahottari ///
    year, ///
    title("Total Road Length by District") ///
    ytitle("Road Length (km)") ///
    xtitle("Year") ///
    legend(order(1 "Kaski" 2 "Jumla" 3 "Mahottari") cols(1)) ///
    name(fig_A1, replace)

graph export "$OUTPUT/Figure_A1_Road_Length.png", replace


/*=======================================================================
   FIGURE A2
   Diesel price time series: Kathmandu
=======================================================================*/

use "$DATA/Kathmandu_Diesel_Price.dta", clear

gen datevar = date(date, "DMY")
format datevar %td
tsset datevar, daily

tsline diesel, ///
    tline(28jul1986 01sep2015) ///
    title("Kathmandu Diesel Prices") ///
    ytitle("Price") ///
    xtitle("Date") ///
    name(fig_A2, replace)

graph export "$OUTPUT/Figure_A2_Diesel_Kathmandu.png", replace


/*=======================================================================
   FIGURE A4
   Interquartile range of coarse rice prices by market district
=======================================================================*/

use "$DATA/interquartile_rice.dta", clear

graph hbox coarse_rice, ///
    over(district, sort(market, descending)) ///
    nooutside ///
    title("Coarse Rice Price Distribution by District") ///
    note("Source: Nepal Agribusiness Promotion and Marketing Development Directorate", span) ///
    name(fig_A4, replace)

graph export "$OUTPUT/Figure_A4_Coarse_Rice_IQR.png", replace


/*=======================================================================
   FIGURE A5
   Interquartile range of wheat flour prices by market district
=======================================================================*/

use "$DATA/interquartile_wheat.dta", clear

rename bord_wf wheat_flour
rename border_market district

graph hbox wheat_flour, ///
    over(district, sort(market, descending)) ///
    nooutside ///
    title("Wheat Flour Price Distribution by District") ///
    note("Source: Nepal Agribusiness Promotion and Marketing Development Directorate", span) ///
    name(fig_A5, replace)

graph export "$OUTPUT/Figure_A5_Wheat_Flour_IQR.png", replace


/*=======================================================================
   FIGURE A6
   Paddy & Wheat Production and Yields (Dual Axis)
=======================================================================*/

use "$DATA/Cereal_Prod.dta", clear

* Convert to thousands
gen paddy_prod_1   = paddy_prod  / 1000
gen wheat_prod_1   = wheat_prod  / 1000
gen wheat_yield_1  = wheat_yield / 1000
gen paddy_yield_1  = paddy_yield / 1000

label var paddy_prod_1  "Paddy Production (000 MT)"
label var wheat_prod_1  "Wheat Production (000 MT)"
label var paddy_yield_1 "Paddy Yield (000 kg/ha)"
label var wheat_yield_1 "Wheat Yield (000 kg/ha)"

twoway ///
    (line paddy_prod_1 year, sort yaxis(1)) ///
    (line wheat_prod_1 year, sort yaxis(1)) ///
    (line paddy_yield_1 year, sort yaxis(2)) ///
    (line wheat_yield_1 year, sort yaxis(2)), ///
    title("Trends in Cereal Production and Yields") ///
    xtitle("Year") ///
    ytitle("Production (000 MT)", axis(1)) ///
    ytitle("Yield (000 kg/ha)", axis(2)) ///
    legend(order(1 "Paddy Prod." 2 "Wheat Prod." 3 "Paddy Yield" 4 "Wheat Yield") cols(2)) ///
    name(fig_A6, replace)

graph export "$OUTPUT/Figure_A6_Prod_Yield_Trends.png", replace

/*=======================================================================
   END OF FILE
=======================================================================*/

display "All Appendix Figures successfully created."
