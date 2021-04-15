# Epi World data package

# Capture args ------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
source <- args[1]

# Load packages -----------------------------------------------------------

library(rsyncrosim)
library(COVID19)
library(dplyr)
library(tidyr)
library(readr)
library(lubridate)

# Load Vars ---------------------------------------------------------------

myLib <- ssimLibrary()
mySce <- scenario()
e <- ssimEnvironment()
transferDir <- e$TransferDirectory

# Source helpers ----------------------------------------------------------

source(file.path(e$PackageDirectory, "epiDataWorld_functions.R"))
source(file.path(e$PackageDirectory, "COVID19DataHub_functions.R"))
source(file.path(e$PackageDirectory, "JHUDirectQuery_functions.R"))

# Define variables (now harcoded) -----------------------------------------

vars <- c("Cases - Daily", "Cases - Cumulative")

# Query inputs ------------------------------------------------------------

inputs <- datasheet(mySce, "epiDataWorld_Inputs", lookupsAsFactors = FALSE)
source <- inputs$DataSourceID

# Check inputs ------------------------------------------------------------

if(grepl("Hub", source)){
  
  input_vars <- COVID19Hub_check_inputs(inputs)
  covidDataSubset <- COVID19Hub_query_clean(inputs)
  
} else if (grepl("Johns Hopkins", source)){
  
  # Use the same function for now for input vars parsing
  input_vars <- COVID19Hub_check_inputs(inputs)
  covidDataSubset <- JHUDirect_query_clean(input_vars, e)
  
}

# Save in epi package -----------------------------------------------------

# Get the vector of jurisdictions
allJuris <- unique(covidDataSubset$Jurisdiction)

# Add the required variables and jurisdictions to the SyncroSim project
saveDatasheet(mySce, 
              data.frame(Name = allJuris), "epi_Jurisdiction")
saveDatasheet(mySce, 
              data.frame(Name = vars), "epi_Variable")

# Process Data ------------------------------------------------------------

if(grepl("Hub", source)){
  
  covidDataFinal <- COVID19Hub_process(vars, covidDataSubset)
  
} else if (grepl("Johns Hopkins", source)){
  
  # Use the same function for now
  covidDataFinal <- COVID19Hub_process(vars, covidDataSubset)
  
}

# Save the data
covidDataFinal$TransformerID="Download World Data"
saveDatasheet(mySce, covidDataFinal, "epi_DataSummary")

# Write out data ----------------------------------------------------------

if(grepl("Hub", source)){
  
  fileName <- COVID19Hub_make_filename(inputs)
  
} else if (grepl("Johns Hopkins", source)){
  
  # Use the same function for now
  fileName <-  COVID19Hub_make_filename(inputs)
  
}

filePath <- file.path(transferDir, fileName)

write.csv(covidDataFinal, filePath, row.names = FALSE)

# Save output info --------------------------------------------------------

download_time <- as.character(Sys.time())

output <- datasheet(mySce, "epiDataWorld_Outputs") %>% 
  add_row()

output$Jurisdiction = input_vars$juris_input
output$DataSourceID = source
output$Level = input_vars$level_input
output$DownloadFile = filePath
output$DownloadDateTime = download_time

saveDatasheet(mySce, output, "epiDataWorld_Outputs")
