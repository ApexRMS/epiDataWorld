# Epi World data package
# Using package COVID19
# WIP

library(rsyncrosim)
library(COVID19)

myLib <- ssimLibrary()
mySce <- scenario()
e <- ssimEnvironment()

source(file.path(e$PackageDirectory, "epiDataWorld_functions.R"))

# Get Input datasheets

inputs <- datasheet(mySce, "epiDataWorld_Inputs", lookupsAsFactors = FALSE)

if (length(inputs$Jurisdiction) != 0){
  
  juris <- inputs$Jurisdiction
  
  if (juris == "World"){
    juris <- NULL
  }
  
} else {
  stop("No Jurisdiction provided")
}

if(length(inputs$Level) != 0){
  level <- lookup_level(inputs$Level)
} else {
  message("No level provided, devfault to level 1 (Country)")
}

# Get data

covidData <- COVID19::covid19(country = juris, level = level, 
                              verbose = FALSE)
