
JHUDirect_query_clean <- function(inputs_vars){

  base_url <- paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/",
                     "master/csse_covid_19_data/csse_covid_19_time_series/")
  
  # For now, just get cases
  ts_cases_url <- paste0(base_url, "time_series_covid19_deaths_global.csv")
  # ts_deaths_url <- paste0(base_url, "time_series_covid19_confirmed_global.csv")
  
  ts_cases <- read_csv(ts_cases_url)
  
  # Format dataset
  ts_cases_clean <- ts_cases %>% 
    pivot_longer(5:ncol(ts_cases), names_to="Date", values_to="Cases") %>% 
    mutate(Date=lubridate::as_date(Date, format="%m/%d/%y")) %>% 
    rename(Province_state = `Province/State`, Country_Region = `Country/Region`)
    
}