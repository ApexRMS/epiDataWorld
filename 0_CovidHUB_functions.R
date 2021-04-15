# Covid Hub Helpers -------------------------------------------------------

COVID19Hub_query_clean <- function(inputs_vars){
  
  # Make admin level name
  admin_level_name <- paste0("administrative_area_level_", 
                             input_vars$level_covid)
  
  # TODO use this to filter data
  #runControl <- datasheet(mySce, "epi_RunControl")
  
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
