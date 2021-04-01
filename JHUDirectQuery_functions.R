
JHUDirect_query_clean <- function(input_vars, env){

  base_url <- paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/",
                     "master/csse_covid_19_data/csse_covid_19_time_series/")
  
  # For now, just get cases
  ts_cases_url <- paste0(base_url, "time_series_covid19_confirmed_global.csv")
  # ts_deaths_url <- paste0(base_url, "time_series_covid19_deaths_global.csv")
  
  ts_cases <- read_csv(ts_cases_url)
  
  # Load crosswalk
  crosswalk <- read_csv(file.path(env$PackageDirectory, "data/HUB_JHU_crosswalk.csv"))
  
  # Format dataset
  ts_cases_clean <- ts_cases %>% 
    pivot_longer(5:ncol(ts_cases), names_to="date", values_to="confirmed") %>% 
    mutate(date=lubridate::as_date(date, format="%m/%d/%y")) %>% 
    rename(Province_state = `Province/State`, 
           Country_Region = `Country/Region`) %>% 
    # Remove prinvince/state at the moment
    select(-c(Province_state, Lat, Long)) %>% 
    rename(Jurisdiction = Country_Region) %>% 
    group_by(Jurisdiction, date) %>% 
    summarise(confirmed = sum(confirmed)) %>% 
    ungroup()
  
  for(row in 1:nrow(crosswalk)){
    vec <- ts_cases_clean$Jurisdiction == crosswalk$JHU[row]
    ts_cases_clean$Jurisdiction[vec] <- crosswalk$HUB[row]
  }
  
  # Simple filtering for now based on input vars
  if (input_vars$level_covid > 1){
    stop("Sub-levels not supported with JHU data at the moment.")
  }
  
  if(!is.null(input_vars$juris_covid)){
    
    covidDataSubset <- ts_cases_clean %>% 
      filter(Jurisdiction == input_vars$juris_covid)
    
    if(nrow(covidDataSubset) == 0){
      stop(paste0("Country <", input_vars$juris_covid, 
                  "> not covered by JHU data or is being mishandled."))
    }
    
  } else {
    
    covidDataSubset <- ts_cases_clean
    
  }
  
  return(covidDataSubset)
}

JHUDirect_process <- function(vars, covidDataSubset){
  
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
  
  return(covidDataFinal)
  
}