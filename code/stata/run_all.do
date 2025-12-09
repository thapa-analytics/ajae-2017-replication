/**************************************************************************
* Project:    AJAE (2017) Replication Package
* File:       run_all.do
* Purpose:    Master script to reproduce main, appendix, and bootstrap
*             results 
** Author:     Ganesh Thapa/Gerald E Shively

* Scripts executed:
*   1. main_results_tables.do    → Tables 1–5
*   2. main_results_figures.do   → Figures 2–5
*   3. appendix_tables.do        → Appendix tables incl. A3–A7, tests
*   4. appendix_figures.do       → Appendix figures A1–A6
*   5. bootstrap_iv.do           → Bootstrap standard errors
*
**************************************************************************/

clear all
set more off

display "==============================================================="
display " AJAE (2017) Replication Package – RUN ALL"
display " Main, Appendix, and Bootstrap results"
display "==============================================================="

*---------------------------------------------------------------
* SET WORKING PATH
*---------------------------------------------------------------
* This file is intended to be executed from:
*   code/stata/run_all.do

cd "../.."                 // Move to project root
display "Project root set to: " c(pwd)

* Ensure output folders exist
cap mkdir "output"
cap mkdir "output/tables"
cap mkdir "output/figures"


*---------------------------------------------------------------
* LOG FILE (optional)
*---------------------------------------------------------------
capture log close
log using "output/replication_log.txt", replace text

display " "
display "---- Starting replication pipeline ----"
display " "


*---------------------------------------------------------------
* SECTION 1 — MAIN RESULTS
*---------------------------------------------------------------

display "Running main results tables (Tables 1–5)..."
do "code/stata/main_results_tables.do"

display "Running main results figures (Figures 2–5)..."
do "code/stata/main_results_figures.do"


*---------------------------------------------------------------
* SECTION 2 — APPENDIX RESULTS
*---------------------------------------------------------------

display "Running appendix tables..."
do "code/stata/appendix_tables.do"

display "Running appendix figures..."
do "code/stata/appendix_figures.do"


*---------------------------------------------------------------
* SECTION 3 — BOOTSTRAP STANDARD ERRORS
*---------------------------------------------------------------

display "Running bootstrap standard error routines..."
do "code/stata/bootstrapping_iv.do"


*---------------------------------------------------------------
* FINALIZE
*---------------------------------------------------------------

display " "
display "==============================================================="
display " REPLICATION COMPLETED SUCCESSFULLY"
display " "
display " Outputs saved to:"
display "   - output/tables/"
display "   - output/figures/"
display " "
display " Scripts executed:"
display "   - main_results_tables.do"
display "   - main_results_figures.do"
display "   - appendix_tables.do"
display "   - appendix_figures.do"
display "   - bootstrapping_iv.do"
display "==============================================================="

log close




