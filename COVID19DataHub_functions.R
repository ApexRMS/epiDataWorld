
COVID19Hub_check_inputs <- function(inputs){
  
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
    
    message("No level provided, default to level 1 (Country)")
    
    level_input <- "(1) Country"
    level_covid <- 1
    
  }
  
  return(list(juris_input = juris_input, 
              juris_covid = juris_covid, 
              level_input = level_input, 
              level_covid = level_covid))
}

COVID19Hub_query_clean <- function(inputs_vars){
  
  # Make admin level name
  admin_level_name <- paste0("administrative_area_level_", 
                             input_vars$level_covid)
  
  # TODO use this to filter data
  runControl <- datasheet(mySce, "epi_RunControl")
  
  # Download data -----------------------------------------------------------
  
  covidData <- COVID19::covid19(country = input_vars$juris_covid, 
                                level = input_vars$level_covid, 
                                verbose = FALSE, 
                                raw = TRUE)
  
  composeName <- !(input_vars$level_covid == 1)
  
  covidDataSubset <- covidData %>% ungroup() %>% 
    select(date, confirmed, Jurisdiction = all_of(admin_level_name)) %>% 
    group_by(Jurisdiction) %>% 
    mutate(Jurisdiction = 
             ifelse(composeName, 
                    paste0(input_vars$juris_input, " - ", Jurisdiction), 
                    Jurisdiction))  %>%
    mutate(confirmed = ifelse(is.na(confirmed), 0, confirmed)) %>% 
    arrange(date)
  
  return(covidDataSubset)
  
}

COVID19Hub_process <- function(vars, covidDataSubset){
  
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

COVID19Hub_make_filename <- function(inputs_vars){
  
  juris_no_space <- gsub("[[:space:]]", "_", inputs_vars$juris_input)
  # level_input <- gsub("[[:space:]]", "_", level_input)
  # level_input <- gsub("[[:punct:]]", "", level_input)
  # level_input <- gsub("[[:digit:]]", "", level_input)
  
  fileName <- paste0("COVID19_Data_", juris_no_space, 
                     "_by_level_", inputs_vars$level_covid, ".csv")
  
  return(fileName)
}