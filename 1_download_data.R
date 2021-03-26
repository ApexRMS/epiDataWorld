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

# Define variables (now harcoded) -----------------------------------------

vars <- c("Cases - Daily", "Cases - Cumulative")

# Query inputs ------------------------------------------------------------

inputs <- datasheet(mySce, "epiDataWorld_Inputs", lookupsAsFactors = FALSE)

# Check jurisdiction
if (length(inputs$Jurisdiction) != 0){
  
  juris_input <- inputs$Jurisdiction
  
  if (juris_input == "World"){
    
    juris_covid <- NULL
    
  } else {
    
    juris_covid <- juris_input
    
  }
  
} else {
  
  stop("No Jurisdiction provided")
  
}

# Check level
if(length(inputs$Level) != 0){
  
  level_input <- inputs$Level
  
  level_covid <- lookup_level(inputs$Level)
  
} else {
  
  message("No level provided, devfault to level 1 (Country)")
  
  level_input <- "Country"
  level_covid <- 1
  
}

# Make admin level name
admin_level_name <- paste0("administrative_area_level_", level_covid)

# TODO use this to filter data
runControl <- datasheet(mySce, "epi_RunControl")

# Download data -----------------------------------------------------------

covidData <- COVID19::covid19(country = juris_covid, 
                              level = level_covid, 
                              verbose = FALSE, 
                              raw = TRUE)

composeName <- !(level_covid == 1)

covidDataSubset <- covidData %>% ungroup() %>% 
  select(date, confirmed, Jurisdiction = all_of(admin_level_name)) %>% 
  group_by(Jurisdiction) %>% 
  mutate(Jurisdiction = ifelse(composeName, paste0(juris_input, " - ", Jurisdiction), 
                               Jurisdiction))  %>%
  mutate(confirmed = ifelse(is.na(confirmed), 0, confirmed)) %>% 
  arrange(date)

# Save in epi package -----------------------------------------------------

# Get the vector of jurisdisctions
allJuris <- unique(covidDataSubset$Jurisdiction)

# Add the required variables and jurisdictions to the SyncroSim project
saveDatasheet(mySce, 
              data.frame(Name = allJuris), "epi_Jurisdiction")
saveDatasheet(mySce, 
              data.frame(Name = vars), "epi_Variable")

# Process Data ------------------------------------------------------------

covidDataFinal <- data.frame()

if ("Cases - Daily" %in% vars){
  
  # Need to apply rollback function
  covidDataFinal <- covidDataFinal %>% 
    bind_rows(
      covidDataSubset %>% 
        rename(Timestep = date, value = confirmed) %>% 
        arrange(Timestep) %>%
        group_modify(~rollback(.x, column = "value")) %>% 
        filter(value >= 0) %>% 
        mutate(Variable = "Cases - Daily") %>% 
        ungroup()
      
    )
  
}

if ("Cases - Cumulative" %in% vars){
  
  # Already cumulative, just need to rename
  covidDataFinal <- covidDataFinal %>% 
    bind_rows(
      covidDataSubset %>% 
        rename(Timestep = date, value = confirmed) %>% 
        mutate(Variable = "Cases - Cumulative") %>% 
        ungroup()
    )
  
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
              RegionalSummaryDataFile = filePath, 
              DownloadDateTime = ""))
output$DownloadDateTime <- as.character(Sys.time())

saveDatasheet(mySce, output, "epiDataWorld_Outputs")
