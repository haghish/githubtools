# Mining Stata Packages to Confirm Unique Package Names and File Names
additional tools for the Stata github package 

> this package includes additional tools for the Stata's [github package](https://github.com/haghish/github/), used 
for mining GitHub repositories, SSC packages, downloading SSC packages, etc. 

## Installation

after installing [github](https://github.com/haghish/github/) package, type:

    github install haghish/githubtools, stable

to install the latest stable release of the package. 

## Mining SSC packages

The `minessc` command creates a data set that list all packages hosted on SSC and also specifies the installable files that are included within each package. Optionally, it also allows you to download all packages and store them in subdirectories. Finally, it also creates a zip-file for each package, based on the release date. The command below generates a data set named archive.dta, which analyzes the SSC packages. To download and archive all of the packages, add the `download` option. For more information, read the command help file by typing `help minessc`.

```js
sscminer, save("archive.dta") 
```


## Mining GitHub for Stata packages

Mining Stata packages on GitHub is s complex process, because there might be Stata packages that are not recognized to be written in Stata language. Furthermore, GitHub API has a limit in the search results and thus, the mining process has to be carried out step by step, based on the frequency of the search results. The `githublistpack` program (for documentation type `help githublistpack`) carries out a consecutive search for Stata repositories and packages. In the code below, I search for 1) repositories with Stata language, 2) repositories in all languages that mention the keyword "Stata" within their repository name, description, or _README.md_ file, and combine the results. The `githublistpack` command automatically examines the repositories to see whether they are installable Stata packages. Next, I will loop through each installable Stata package to see whether it includes a dependency file, as specified with _dependency.do_ file, and then, generate the `gitget.dta` data set, which is used by the `gitget` command, in [github package](https://github.com/haghish/github). 

```js
// mining repositories in Stata language
githublistpack , language(Stata) append replace all in(all)  ///
    perpage(100) save("archive1") duration(1) 

// mining stata-related repositories in all languages
githublistpack stata, language(all) append all in(all)       ///
    perpage(100) replace save("archive2") duration(1) 

// merging the data sets
use "archive2.dta", clear
append using "archive1.dta"
duplicates drop address, force
drop _merge 
saveold "archive.dta", replace

// checking for package dependency
use "archive.dta", clear
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

saveold "archive.dta", replace

// generating gitget data set
use "archive.dta", clear
keep if installable == 1
saveold "gitget.dta", replace
```
