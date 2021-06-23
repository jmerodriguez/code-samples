*World Development Indicators - School Enrollment by Level and Gender

*Plot average school enrollment by Region - By Gender and Level
clear all 
use "school_enrollment_WB.dta"

drop yr2001-yr2009 yr2018-yr2020
destring yr2010-yr2017, force replace
g id = _n

reshape long yr, i(id) j(year)

foreach i in "FE" "MA" {
replace seriescode = "primary_`i'" if seriescode == "SE.PRM.NENR.`i'"
replace seriescode = "secondary_`i'" if seriescode == "SE.SEC.NENR.`i'"
replace seriescode = "tertiary_`i'" if seriescode == "SE.TER.ENRR.`i'"
}
*
drop if seriescode == ""

drop id seriesname
egen id = group(countrycode year)

reshape wide yr, i(id) j(seriescode) string 
drop id

bys countrycode: egen tot_nonm = count(yrprimary_FE)
save school_enrollment, replace

*Assign Countries to their World Bank Region
import delimited "world-regions-according-to-the-world-bank.csv", clear 

keep code worldregionaccordingtotheworldba
rename code countrycode
rename worldregionaccordingtotheworldba WBregion

save country_WBregion, replace

merge 1:m countrycode using school_enrollment
keep if _merge == 3
drop _merge

*Calculate School Enrollment Averages per Year per Region
collapse (mean) yrprimary_FE-yrtertiary_MA, by(WBregion year)
/*note: for making this code shorter, I ignored the fact that Regions
averages for different year might be considering different countries
because of data issues*/

*Graph the trends

