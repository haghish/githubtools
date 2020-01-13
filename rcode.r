# -----------------------------------------------------------------------------------
githubunique = function(df, search="pkg", sleep=2) {
  
  warning("This might take a long time tp complete...")
  
  # required libraries
  library(jsonlite)
  
  # variables
  data = NULL
  
  for (i in 1:nrow(df)) {
    loop = 0
    address = df$address[i]
    URL = paste0("https://api.github.com/search/code?q=extension:",search,"+repo:",
                 address)
    cat("\n")
    message(paste0(i,".  ", URL))
    json = tryCatch(
      {
        fromJSON(URL)
      },
      error=function(cond) {
        message(cond)
        cat("\n")
        return(NULL)
      }
    )
    
    # repeate a loop to examin the API 60 times
    # ---------------------------------------
    if (is.null(json)) loop = 1
    else loop = 0
    
    N = 1
    while(loop == 1) {
      Sys.sleep(sleep*5)
      warning("API error. wait a few seconds")
      if (N >= 10) {
        loop = 0
        print(paste(address, "seems to have a vital problem"))
      } else {
        json = tryCatch(
          {
            fromJSON(URL)
          },
          error=function(cond) {
            message(cond)
            cat("\n")
            return(NULL)
          }
        )
        if (is.null(json)) loop = 1
        else loop = 0
      }
      
      N = N + 1
    } 
    
    if (!is.null(json)) {
      json = as.data.frame(json[['items']][c("name","path")])
      if (ncol(json) > 0) {
        json$address = address
      } else {
        json = data.frame(name=NA, path=NA, address=address)
      }
      print(json)
      data = rbind(data, json)
    }
    Sys.sleep(sleep)
  }
  return(data)
}

# -----------------------------------------------------------------------------------

# change the working directory to the packagelist directory
setwd("//winfs-uni.top.gwdg.de/ebadfardzade$/githubtools")
library(haven)

# use the haven R package to load Stata data
archive = read_dta("./data/archive.dta")
archive = unique(archive[,c("address")] )

# parse the json data obtained from the API
data = githubunique(archive, search="pkg")
data$name = tools::file_path_sans_ext(basename(data$name))

# convert factor to string
data$address = as_factor(data$address)
data$address = as.character(data$address)

# write the results in a Stata file
write_dta(data, "./data/unique.dta")