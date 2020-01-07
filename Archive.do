/***
PACKAGE LIST
============

This file includes a series of code for building an archive of all existing 
Stata packages and repositories on GitHub and SSC. Executing this file may 
take many hours. 

To the maintainers
------------------

After the first execution, you don't need to run the whole file again. Instead,
you can go to __SECTION 2: UPDATING__ and only update the archive, from the 
last date. 


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

//Append githubfiles and sscfiles
use "./data/githubfiles.dta", clear
append using "./data/sscfiles.dta"
sort packagename
save "./githubfiles.dta", replace


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

Instruction and code is in __github_update.do__
***/
