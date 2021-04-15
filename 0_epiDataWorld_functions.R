# Package Helpers ---------------------------------------------------------

# Load and check input data
load_inputs <- function(backend, mySce, e){
  
  if(backend == "JHU"){
    
    inputsheet <- "epiDataWorld_InputsJHU"
    
  } else if(backend == "HUB"){
    
    inputsheet <- "epiDataWorld_InputsCovidHUB"
    
  }
  
  inputs <- datasheet(mySce, inputsheet, lookupsAsFactors = FALSE)
  input_vars <- check_inputs(inputs)
  
  if(backend == "HUB"){
    
    
    covidDataSubset <- COVID19Hub_query_clean(inputs)
    
  } else if (backend == "JHU"){
    
    covidDataSubset <- JHUDirect_query_clean(input_vars, e)
    
  }
  
  outList <- list(inputs = inputs, 
                  input_vars = input_vars, 
                  covidDataSubset = covidDataSubset)
  
  return(outList)
    
}

# Check inputs
check_inputs <- function(inputs){
  
  # Check jurisdiction
  if (length(inputs$Country) != 0){
    
    juris_input <- inputs$Country
    
    if (juris_input == "All Countries"){
      
      juris_covid <- NULL
      
    } else {
      
      juris_covid <- juris_input
      
    }
    
  } else {
    
    stop("No Country provided")
    
  }
  
  # Check level
  if(length(inputs$Level) != 0){
    
    level_input <- inputs$Level
    
    level_covid <- lookup_level(inputs$Level)
    
  } else {
    
    message("No level provided, default to level 1 (Country)")
    
    level_input <- "(1) Country"
    level_covid <- 1
    
  }
  
  return(list(juris_input = juris_input, 
              juris_covid = juris_covid, 
              level_input = level_input, 
              level_covid = level_covid))
}

# Save jurisdictions to the epi package datasheets
save_to_epi <- function(dataSubset, mySce, vars){
  
  # Get the vector of jurisdictions
  allJuris <- unique(dataSubset$Jurisdiction)
  
  # Add the required variables and jurisdictions to the SyncroSim project
  saveDatasheet(mySce, 
                data.frame(Name = allJuris), "epi_Jurisdiction")
  saveDatasheet(mySce, 
                data.frame(Name = vars), "epi_Variable")
  
}

# Replace level string
lookup_level <- function(level){
  
  if(is.character(level)){
    
    if(grepl("Country", level,  fixed = TRUE)){
      level_int = 1
    } else if (grepl("State", level,  fixed = TRUE)){
      level_int = 2
    } else if (grepl("Lower", level,  fixed = TRUE)){
      level_int = 3
    }
    
  } else {
    
    stop("Level should be of type character")
    
  }
  
  return(level_int)
  
}

# Calculate rollback
rollback <- function(df, column){
  
  if(is.data.frame(df)){
    
    df[[column]] <- df[[column]] - lag(df[[column]])
    df[[column]][is.na(df[[column]])] <- 0
    
  } else {
    
    stop("df should be of type data.frame")
    
  }
  
  return(df)
  
}

# Process data
process_data <- function(vars, covidDataSubset){
  
  covidDataFinal <- data.frame()
  
  if ("Cases - Daily" %in% vars){
    
    # Need to apply rollback function
    covidDataFinal <- covidDataFinal %>% 
      bind_rows(
        covidDataSubset %>% 
          rename(Timestep = date, value = confirmed) %>% 
          arrange(Timestep) %>%
          group_by(Jurisdiction) %>%
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
  
  return(covidDataFinal)
  
}

# Make file name
make_filename <- function(inputs_vars){
  
  juris_no_space <- gsub("[[:space:]]", "_", inputs_vars$juris_input)
  # level_input <- gsub("[[:space:]]", "_", level_input)
  # level_input <- gsub("[[:punct:]]", "", level_input)
  # level_input <- gsub("[[:digit:]]", "", level_input)
  
  fileName <- paste0("COVID19_Data_", juris_no_space, 
                     "_by_level_", inputs_vars$level_covid, ".csv")
  
  return(fileName)
}

# Save output info
save_output_info <- function(mySce, input_vars, backend, filePath){
  
  if(backend == "JHU"){
    
    outputsheet <- "epiDataWorld_OutputsJHU"
    sourceID <- "Johns Hopkins University"
    
  } else if(backend == "HUB"){
    
    outputsheet <- "epiDataWorld_OutputsCovidHUB"
    sourceID <- "COVID-19 Data Hub"
    
  }
  
  download_time <- as.character(Sys.time())
  
  output <- datasheet(mySce, outputsheet) %>% add_row()
  
  output$Jurisdiction = input_vars$juris_input
  output$DataSourceID = sourceID
  output$Level = input_vars$level_input
  output$DownloadFile = filePath
  output$DownloadDateTime = download_time
  
  saveDatasheet(mySce, output, outputsheet)
}