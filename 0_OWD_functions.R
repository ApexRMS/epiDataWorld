
# Libraries ---------------------------------------------------------------

library(readr)

# OWD Helpers -------------------------------------------------------------

load_raw_data <- function(the_url = OWD_URL){
  
  df <- readr::read_csv(the_url, 
                        col_types = cols(
                          .default = col_double(),
                          iso_code = col_character(),
                          continent = col_character(),
                          location = col_character(),
                          date = col_date(format = ""),
                          icu_patients = col_double(),
                          icu_patients_per_million = col_double(),
                          hosp_patients = col_double(),
                          hosp_patients_per_million = col_double(),
                          weekly_icu_admissions = col_double(),
                          weekly_icu_admissions_per_million = col_double(),
                          weekly_hosp_admissions = col_double(),
                          weekly_hosp_admissions_per_million = col_double(),
                          tests_units = col_character()
                        ))
  
  return(df)
  
}

OWDDirect_query_clean <- function(input_vars, env, sce){
  
  raw <- load_raw_data()
  
  if(input_vars$juris_covid == "[All Countries]"){
    
    all_juris <- datasheet(sce, "epiDataWorld_AllJurisdictions")
    all_juris <- all_juris[all_juris$name != "[All Countries]", ]
    filter_loc <- all_juris$name
    
  } else {
    
    filter_loc <- input_vars$juris_covid
      
  }
  
  covidDataSubset <- raw %>% select(Jurisdisction = location, Timestep = date, 
                             all_of(OWDLOOKUP$RAWVARS)) %>% 
    pivot_longer(all_of(OWDLOOKUP$RAWVARS), names_to = "Variable", 
                 values_to = 'Value') %>% 
    filter(Jurisdiction %in% filter_loc)
  
  return(list(subset = covidDataSubset, 
              raw = raw))
  
}