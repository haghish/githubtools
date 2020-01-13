capture cd "/Users/haghish/Dropbox/Submitted & Published Articles/PREPARATION/github/images"

use "https://github.com/haghish/github/blob/master/packagelist/archive.dta?raw=true", clear

gen year = year(dofc(created))
keep if year >= 2013 & year < 2020
table installable
keep if language == "Stata" | installable == 1
//some repositories include multiple packages. now we're counting number of repos:
duplicates drop address, force
txt "number of repositories " _N



local reponame "Number of newly created repositories"
local packname "Stata packages on Github by date of creation"

local reponame "Stata Repositories"
graph bar (count) installable, over(year) b1title("Creation date") ///
ytitle("Public repositories") ytitle(, margin(bargraph)) scheme(sj)       ///
title("`reponame'") name(repo, replace)    
graph export "repositories.png", replace      

capture use "C:\Users\haghish.fardzadeh\Documents\GitHub\github\gitget.dta", clear 
capture use "/Users/haghish/Documents/Packages/github/gitget.dta", clear
gen year = year(dofc(created))
keep if year >= 2013 & year < 2019
txt "number of repositories " _N

local packname "Stata packages"
graph bar (count) installable if installable == 1, over(year) ///
ytitle("Public packages (installable repositories)") ytitle(, margin(bargraph))           ///
b1title("Creation date") scheme(sj)    ///
title("`packname'") name(package, replace)
graph export "packages.png", replace  


graph combine repo package, ysize(4) xsize(6.75) scheme(sj) ///
title("Stata repositories and packages on GitHub") 
graph export "combined.png", replace 


// ANALYZING STATA PACKAGES
// =============================================================================

use githubfiles, clear
qui gen uniq = address + "/" + packagename
qui gen extension = substr(file, -5, .)   
qui gen ado = strpos(extension, ".ado")
qui gen mata = strpos(extension, ".mata")
recode ado (2 = 1)

// duplicate report of the packagename
duplicates tag uniq if ado == 1, generate(duplicates)
gen adototal = duplicates + 1

drop duplicates
duplicates tag uniq if mata == 1, generate(duplicates)
gen matatotal = duplicates + 1

drop duplicates
sort packagename

recode matatotal (. = 0)
recode adototal (. = 0)




// Note that repositories that include multiple packages will only be forced to have one package
// because the path to the pkg is not included to identify unique packages

// GITHUB
preserve
keep if address != "SSC"
gen scripttotal = matatotal + adototal
gsort   packagename -scripttotal
duplicates drop uniq, force
univar scripttotal
tabulate scripttotal
restore


preserve
keep if address == "SSC"
gen scripttotal = matatotal + adototal
gsort   packagename -scripttotal
duplicates drop uniq, force
univar scripttotal
tabulate scripttotal
restore
















// EXTRA
preserve
keep if address != "SSC"
di _N
keep if ado == 1
duplicates drop uniq, force
di as err "number of packages that include {bf:ADO}: " _N
univar adototal
tabulate adototal
restore

preserve
keep if address != "SSC"
keep if mata == 1
duplicates drop uniq, force
di as err "number of packages that include {bf:MATA}: " _N
univar matatotal
tabulate matatotal
restore


// Analyze the SSC archive
preserve
keep if address == "SSC"
keep if adototal >= 1
di as err "number of packages that include {bf:ADO}: " _N
univar adototal
tabulate adototal
restore


preserve
keep if address == "SSC"
keep if matatotal >= 1
di as err "number of packages that include {bf:MATA}: " _N
univar matatotal
tabulate matatotal
restore
