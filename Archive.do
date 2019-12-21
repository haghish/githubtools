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

/***
SECTION 2: BUILDING THE GITHUB ARCHIVE
================================================================================

Instruction and code is in __github_build.do__
***/


/***
SECTION 3: UPDATING THE GITHUB ARCHIVE
================================================================================

Instruction and code is in __github_update.do__
***/
