/*

*/


/***
PACKAGE LIST
============

This file includes a series of code for building an archive of all existing 
Stata packages and repositories on GitHub and SSC. Executing this file may 
take many hours. 

In addition to the 'github' package, you also need the following packages:

        github install haghish/markdoc, stable
        github install haghish/rcall
		github install haghish/githubtools
        ssc install sdecode

make sure your _rcall_ package is connected to R. For more information, visit
<https://github.com/haghish/rcall>

before runing the code below, save the files on your hard drive, place them in 
a directory, and change your working directory to the specified directory


SECTION 1: BUILDING THE SSC ARCHIVE
================================================================================

Building the SSC archive is much faster and simpler than GitHub API search and 
it takes an hour or so.

***/


// -----------------------------------------------------------------------------
// Required packages
// =============================================================================
ssc install confirmdir
ssc install dirlist

// -----------------------------------------------------------------------------
// Create the SSC archive dataset and download the files
// =============================================================================
sscminer, save("./data/sscarchive") //download //remove
qui erase ssclist.log


// organize the information to be merged with githubfiles.dta
// ----------------------------------------------------------
use "./data/sscarchive.dta", clear
gen dummy = 1
rename package packagename
rename files file
keep packagename  file dummy
local last = _N
local OBS  = _N
forval N = 1/`last' {
  local pname = packagename[`N']
  local filenames = file[`N']
  tokenize "`filenames'", parse(";")
	while !missing("`1'") {
      if "`1'" != ";" {
		local OBS = `OBS' + 1
		qui set obs `OBS'
		qui replace packagename = "`pname'" in `OBS'
		qui replace file = "`1'" in `OBS'
	  }
      macro shift
  } 
}

drop if dummy==1
drop dummy
gen address = "SSC"
order address packagename file
save "./data/sscfiles.dta", replace




/***
SECTION 2: BUILDING THE GITHUB ARCHIVE
================================================================================
***/

// mining repositories in Stata language
githublistpack , language(Stata) append replace all in(all)                     ///
    perpage(100) save("./data/archive1") duration(1) delay(15000)

// mining stata-related repositories in all languages
githublistpack stata, language(all) append all in(all)                          ///
    perpage(100) replace save("./data/archive2") duration(1) delay(30000)


/***
SECTION 3: UPDATING THE GITHUB ARCHIVE
================================================================================

use the reference() option to set the starting date of the search. 
the last update was "01.01.2020". For more details read __githublistpack__ help 
file
***/

// merging the data sets
use "./data/archive2.dta", clear
append using "./data/archive1.dta"
duplicates drop address name pushed, force
saveold "./data/archive.dta", replace

// checking for package dependency
use "./data/archive.dta", clear
capture drop dependency
generate dependency = .

local j 0
local last = _N
forval N = 1/`last' {
  if installable[`N'] == 1 {
    local j = `j'+1
    local address : di address[`N']
    capture githubdependency `address'
    if `r(dependency)' == 1 {
      display as txt "`N'/`last'" 
      replace dependency = 1 in `N'
    }
  }
}
saveold "./data/archive_base.dta", replace

/***
1.3 Check the pkg files and package names
-----------------------------------------

we need to searche for all packages inside the 
repositories and also examines the package names. For 
example, if the package name is not identical to the 
repository name, this process will correct the package name 
in the data set. 

The results of this search are stored in the 'unique.dta' 
data set. there are 2 ways to generate the unique data set: 

1. using rcode.do with RCALL package
2. running rcode.r in R console

both files are located in the packagelist directory. After
generating the 'unique' data, update the data sets.

AFTER RUNNING rcode.r FILE, execute:

***/

use ./data/unique.dta, clear
drop if path == ""
gen toc = 1
saveold "temp.dta", replace

use ./data/archive_base.dta, clear
duplicates drop address, force
merge 1:m address using "temp.dta"
capture drop _merge 

replace installable = 1 if (path != "") & (toc == 1) 

saveold "archive.dta", replace
erase temp.dta


// REMEMBER THAT FROM NOW ON, 'address' is no longer unique

/***
Generate gitget data set, for installable packages
--------------------------------------------------

Here we generate a dataset for gitget command, as well as a Markdown
list for all of the recognized packages:
***/
use "./data/archive.dta", clear
keep if installable == 1
saveold "./data/gitget.dta", replace

gitgetlist, export("./data/gitget.md")



/***
1.7 Creating githubfiles data
--------------------------------
***/

clear
tempfile githubfiles
qui generate str20 address = ""
qui generate str20 packagename = ""
qui generate str20 file = ""
qui save "./data/githubfiles.dta", replace

use ./data/gitget.dta, clear

//ATTENTION: currently it only searches the master branch...
tempfile confirm
local N : di _N
forval i = 1/`N' {
	
	tempfile api 
	tempname hitch 
	qui local link : display "https://raw.githubusercontent.com/" address[`i'] "/master/" path[`i']
  capture quietly copy  "`link'" `api', replace
	local loop = 0
	local count = 1
	local continue = 1
	
	if _rc != 0 {
		local continue = 0
		di as err "`link'"
		local loop = 1
		while `loop' == 1 {
			di as txt "wait a few seconds and try again (`count'/3)"
			sleep 3000
			local count = `count' + 1
			capture quietly copy  "`link'" `api', replace
			if _rc == 0 {
				local loop = 0
				local continue = 1
			}
			if `count' > 3 {
				local loop = 0
				di as err "no luck!"
			}
		}
	}
	
  if `continue' == 1 {
		display as txt "`i'"
		local address = address[`i']
		local packagename = name[`i']
		file open `hitch' using "`api'", read
		file read `hitch' line
		while r(eof) == 0 { 
			capture local line : subinstr local line "`" "", all
			capture if substr(trim(`"`macval(line)'"'),1,2) == "F " |       ///
			substr(trim(`"`macval(line)'"'),1,2) == "f " {
				preserve
				use githubfiles.dta, clear
				local NEXT : di _N + 1
				qui set obs `NEXT'
				qui replace address = "`address'" in `NEXT'
				qui replace packagename = "`packagename'" in `NEXT'
				qui replace file = substr(trim(`"`macval(line)'"'),3,.) in `NEXT'
				qui save "githubfiles.dta", replace
				restore
			}
			file read `hitch' line
    }
		file close `hitch'
		capture rm `"`api'"'
  }
	
	sleep 250
}

saveold "./data/githubfiles.dta", replace

/***
Append githubfiles and sscfiles
===============================

***/

use "./data/githubfiles.dta", clear
append using "./data/sscfiles.dta"
sort packagename
qui gen uniq2 = address + "/" + packagename + "/" + file
duplicates drop uniq, force
drop uniq
save "./githubfiles.dta", replace
