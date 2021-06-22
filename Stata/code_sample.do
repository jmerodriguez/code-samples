*World Development Indicators - School Enrollment by Level and Gender

*Plot average school enrollment by Region - By Gender and Level
clear all 
use "school_enrollment_WB.dta"

drop yr2001-yr2005 yr2018-yr2020

destring yr2006-yr2017, force replace

egen aux = rowmiss(yr*)
drop if aux != 0
