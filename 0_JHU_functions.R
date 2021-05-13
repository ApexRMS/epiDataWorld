# JHU Helpers -------------------------------------------------------------

JHUDirect_query_clean <- function(input_vars, env){
  
  base_url <- paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/",
                     "master/csse_covid_19_data/csse_covid_19_time_series/")
  
  # Load crosswalk
  crosswalk <- read_csv(file.path(env$PackageDirectory, "data/HUB_JHU_crosswalk.csv"))
  
  # Control what is downloaded based on user inputs 
  # As long as not empty...
  if(!is.null(input_vars$juris_covid)){
    
    if(input_vars$juris_covid == "United States"){ # IF US
      
      if (input_vars$level_covid == 1){ 
        # Global data, filtered to US
        the_data <- 
          JHU_download_data(base_url, vars = c("confirmed", "deaths", "recovered"), 
                            scope = "global") %>% 
          JHU_clean_data(scope = "global", level = 1, crosswalk = crosswalk, 
                         filter_country = "United States")
        
      } else {
        the_data <- 
          JHU_download_data(base_url, vars = c("confirmed", "deaths"), 
                            scope = "US") %>% 
          JHU_clean_data(scope = "US", level = input_vars$level_covid, 
                         crosswalk = crosswalk)
      }
      
    } else { # Either all countries or specific countries
      
      # Global Data
      
      if(input_vars$juris_covid == "[All Countries]"){
        # do not filter
        the_data <- 
          JHU_download_data(base_url, vars = c("confirmed", "deaths", "recovered"), 
                            scope = "global") %>% 
          JHU_clean_data(scope = "global", level = input_vars$level_covid, 
                         crosswalk = crosswalk)
      } else {
        the_data <- 
          JHU_download_data(base_url, vars = c("confirmed", "deaths", "recovered"), 
                            scope = "global") %>% 
          JHU_clean_data(scope = "global", level = input_vars$level_covid, 
                         crosswalk = crosswalk, 
                         filter_country = input_vars$juris_covid)
      }
      
    } 
    
  } else { # NULL, assume all countries?
    the_data <- 
      JHU_download_data(base_url, vars = c("confirmed", "deaths", "recovered"), 
                        scope = "global") %>% 
      JHU_clean_data(scope = "global", level = input_vars$level_covid, 
                     crosswalk = crosswalk)
  }
  
  return(the_data)
}

JHU_download_data <- function(base_url, vars, scope){
  
  all_urls <- paste0(base_url, "time_series_covid19_", vars, "_", scope, ".csv")
  df_list <- lapply(X = all_urls, FUN = read_csv)
  
  names(df_list) <- vars
  the_data <- bind_rows(df_list, .id = "Variable") 
  
  return(the_data)
  
}

JHU_clean_data <- function(df, scope, level, crosswalk, 
                           filter_country = "[All Countries]"){
  
  if(scope == "US"){
    
    df <-   df %>% 
      select(-c(UID, iso2, iso3, code3, FIPS, 
                Population, Lat, Long_, Combined_Key)) 
    
    # Replace by crosswalk
    for(row in 1:nrow(crosswalk)){
      vec <- df$Country_Region == crosswalk$JHU[row]
      df$Country_Region[vec] <- crosswalk$HUB[row]
    }
    
    if(level == 1){
      
      df <- df %>% 
        mutate(Jurisdiction = Country_Region)
      
    } else if (level == 2){
      
      df <- df %>% 
        mutate(Jurisdiction = paste0(Country_Region, " - ", Province_State))
      
    } else if (level == 3){
      
      df <- df %>% 
        mutate(Jurisdiction = paste0(Country_Region, " - ", 
                                     Province_State, " - ", 
                                     Admin2))
      
    }
    
    df <- df %>% 
      select(-c(Country_Region, Admin2, Province_State)) %>% 
      relocate(Jurisdiction)
    
  } else if(scope == "global"){
    
    df <- df %>% 
      rename(Province_State = `Province/State`, 
             Country_Region = `Country/Region`) %>% 
      select(-c(Lat, Long))
    
    # Replace by crosswalk
    for(row in 1:nrow(crosswalk)){
      vec <- df$Country_Region == crosswalk$JHU[row]
      df$Country_Region[vec] <- crosswalk$HUB[row]
    }
    
    if(filter_country != "[All Countries]"){
      df <- df %>% 
        filter(Country_Region == filter_country) 
    }
    
    if(level == 1){
      
      df <- df %>% 
        mutate(Jurisdiction = Country_Region)
      
    } else if (level == 2){
      
      if(is.na(df$Province_State[1])){
        stop("No province/state available for this country.")
      } else {
        df <- df %>% 
          filter(!is.na(Province_State)) %>% 
          mutate(Jurisdiction = paste0(Country_Region, " - ", Province_State))
      }
      
      if(filter_country == "Canada"){
        df <- df %>% 
          filter(!(Province_State %in% c("Diamond Princess", 
                                         "Grand Princess", 
                                         "Repatriated Travellers")))
      }
      
      
    } else if (level == 3){
      
      stop("Lower levels not supported with JHU data for countries other than the US.")
      
    }
    
    df <- df %>% 
      select(-c(Country_Region, Province_State)) %>% 
      relocate(Jurisdiction)
    
  }
  
  # Format dataset
  df_clean <- df %>% 
    pivot_longer(where(is.double), names_to="Timestep", values_to="Value") %>% 
    mutate(Timestep=lubridate::as_date(Timestep, format="%m/%d/%y")) %>% 
    group_by(Jurisdiction, Variable, Timestep) %>% 
    summarise(Value = sum(Value)) %>% 
    ungroup() %>% 
    pivot_wider(names_from = Variable, values_from = Value)
  
  return(df_clean)
  
}