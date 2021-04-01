
COVID19Hub_query_clean <- function(inputs){
  
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
    
    level_input <- "(1) Country"
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
  
  return(covidDataSubset)
  
}

COVID19Hub_process <- function(vars, covidDataSubset){
  
  covidDataFinal <- data.frame
  
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
  
  return(covidDataFinal)
  
}