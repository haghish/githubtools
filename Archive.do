// -----------------------------------------------------------------------------
// Required packages
// =============================================================================
ssc install confirmdir
ssc install dirlist

// -----------------------------------------------------------------------------
// Create the SSC archive dataset and download the files
// =============================================================================
sscminer, save("sscarchive") //download //remove

qui erase ssclist.log
use "archive.dta" , clear

/* 
doing a bit more with rcall
*/



