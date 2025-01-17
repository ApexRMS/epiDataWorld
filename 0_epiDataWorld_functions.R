# Package Helpers ---------------------------------------------------------

# Load and check input data
load_inputs <- function(backend, mySce, e){
  
  if(backend == "JHU"){
    
    inputsheet <- "epiDataWorld_InputsJHU"
    
  } else if(backend == "HUB"){
    
    inputsheet <- "epiDataWorld_InputsCovidHub"
    
  } else if(backend == "OWD"){
    
    inputsheet <- "epiDataWorld_InputsOWD"
    
  }
  
  inputs <- datasheet(mySce, inputsheet, lookupsAsFactors = FALSE)
  input_vars <- check_inputs(inputs)
  
  if(backend == "HUB"){
    
    covidDataSubset <- COVID19Hub_query_clean(input_vars)
    
  } else if (backend == "JHU"){
    
    covidDataSubset <- JHUDirect_query_clean(input_vars, e)
    
  } else if (backend == "OWD"){
    
    covidDataSubset <- OWDDirect_query_clean(input_vars, e, mySce)
    
  }
  
  outList <- list(inputs = inputs, 
                  input_vars = input_vars, 
                  covidDataSubset = covidDataSubset$subset, 
                  rawData = covidDataSubset$raw)
  
  return(outList)
  
}

# Check inputs
check_inputs <- function(inputs){
  
  # Check jurisdiction
  if (length(inputs$Country) != 0){
    
    juris_input <- inputs$Country
    
    if (juris_input == "[All Countries]"){
      
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
  
  # browser()
  
  if(is.data.frame(df)){
    
    df <- df %>% 
      mutate(across(!where(is.Date), 
                    ~(.x - lag(.x, n = 1L, default = 0)), 
                    .names = "daily{.col}"))
    
  } else {
    
    stop("df should be of type data.frame")
    
  }
  
  return(df)
  
}

# Process data
process_data <- function(covidDataSubset, lookup){
  
  # browser()
  
  covidDataFinal <- covidDataSubset %>%
    arrange(Timestep) %>%
    group_by(Jurisdiction) %>%
    nest() %>% 
    mutate(data = list(purrr::map_df(data, ~rollback(.x)))) %>% 
    unnest(cols = c(data)) %>%  
    pivot_longer(cols = starts_with(c("daily", "vacc", "test", "conf", "rec", "dea")), 
                 names_to = "Variable", values_to = "Value") %>% 
    left_join(lookup, by = c("Variable" = "RAWVARS")) %>% 
    select(-c(Variable)) %>% rename(Variable = VARS) %>% 
    filter(!is.na(Variable))
  
  return(covidDataFinal)
  
}

# Make file name
make_filename <- function(inputs_vars, backend){
  
  juris_no_space <- gsub("[[:space:]]", "_", inputs_vars$juris_input)
  # level_input <- gsub("[[:space:]]", "_", level_input)
  # level_input <- gsub("[[:punct:]]", "", level_input)
  # level_input <- gsub("[[:digit:]]", "", level_input)
  
  fileName <- paste0("COVID19_Data_", juris_no_space, 
                     "_by_level_", inputs_vars$level_covid, 
                     "_ ", backend, ".csv")
  
  return(fileName)
}

# Save output info
save_output_info <- function(mySce, input_vars, backend, filePath){
  
  if(backend == "JHU"){
    
    outputsheet <- "epiDataWorld_OutputsJHU"
    sourceID <- "Johns Hopkins University"
    URL <- JHU_BASE_URL
    
  } else if(backend == "HUB"){
    
    outputsheet <- "epiDataWorld_OutputsCovidHub"
    sourceID <- "COVID-19 Data Hub"
    URL <- HUB_URL

  } else if(backend == "OWD"){
    
    outputsheet <- "epiDataWorld_OutputsOWD"
    sourceID <- "Our World in Data"
    URL <- OWD_URL
    
  }
  
  download_time <- as.character(Sys.time())
  
  output <- datasheet(mySce, outputsheet) %>% add_row()
  
  output$Jurisdiction = input_vars$juris_input
  output$DataSourceID = sourceID
  output$Level = input_vars$level_input
  output$DownloadFile = filePath
  output$DownloadURL = URL
  output$DownloadDateTime = download_time
  
  saveDatasheet(mySce, output, outputsheet)
}