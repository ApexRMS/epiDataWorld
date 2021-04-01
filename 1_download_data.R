# Epi World data package
# Using package COVID19
# WIP

# Load packages -----------------------------------------------------------

library(rsyncrosim)
library(COVID19)
library(dplyr)
library(tidyr)

# Load Vars ---------------------------------------------------------------

myLib <- ssimLibrary()
mySce <- scenario()
e <- ssimEnvironment()
transferDir <- e$TransferDirectory

# Source helpers ----------------------------------------------------------

source(file.path(e$PackageDirectory, "epiDataWorld_functions.R"))
source(file.path(e$PackageDirectory, "COVID19DataHub_functions.R"))
source(file.path(e$PackageDirectory, "epiDataWorld_functions.R"))

# Define variables (now harcoded) -----------------------------------------

vars <- c("Cases - Daily", "Cases - Cumulative")

# Query inputs ------------------------------------------------------------

inputs <- datasheet(mySce, "epiDataWorld_Inputs", lookupsAsFactors = FALSE)
source <- inputs$Source

# Check inputs ------------------------------------------------------------

if(grepl("Hub", source)){

  covidDataSubset <- COVID19Hub_query_clean(inputs)

} else if (grepl("JHU", source)){

  covidDataSubset <- JHUDirect_query_clean(inputs)

}

# Save in epi package -----------------------------------------------------

# Get the vector of jurisdisctions
allJuris <- unique(covidDataSubset$Jurisdiction)

# Add the required variables and jurisdictions to the SyncroSim project
saveDatasheet(mySce, 
              data.frame(Name = allJuris), "epi_Jurisdiction")
saveDatasheet(mySce, 
              data.frame(Name = vars), "epi_Variable")

# Process Data ------------------------------------------------------------

if(grepl("Hub", source)){
  
  covidDataFinal <- COVID19Hub_process(vars, covidDataSubset)
  
} else if (grepl("JHU", source)){
  
  covidDataSubset <- JHUDirect_process(vars, covidDataSubset)
  
}

# Save the data
saveDatasheet(mySce, covidDataFinal, "epi_DataSummary")

# Write out data ----------------------------------------------------------

juris_no_space <- gsub("[[:space:]]", "_", juris_input)
# level_input <- gsub("[[:space:]]", "_", level_input)
# level_input <- gsub("[[:punct:]]", "", level_input)
# level_input <- gsub("[[:digit:]]", "", level_input)

fileName <- paste0("COVID19_Data_", juris_no_space, "_by_level_", level_covid, ".csv")

filePath <- file.path(transferDir, fileName)

write.csv(covidDataFinal, filePath, row.names = FALSE)

# Save output info --------------------------------------------------------

output <- datasheet(mySce, "epiDataWorld_Outputs") %>% 
  addRow(list(Jurisdiction = juris_input,
              Level = level_input, 
              RegionalSummaryDataFile = filePath, 
              DownloadDateTime = ""))
output$DownloadDateTime <- as.character(Sys.time())

saveDatasheet(mySce, output, "epiDataWorld_Outputs")
