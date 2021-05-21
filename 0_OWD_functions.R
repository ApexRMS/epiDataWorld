
# Libraries ---------------------------------------------------------------

library(readr)

# OWD Helpers -------------------------------------------------------------

load_raw_data <- function(the_url = OWID_URL){
  
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

OWDDirect_query_clean <- function(input_vars, env){
  
  raw <- load_raw_data()
  
  return(list(subset = the_data, 
              raw = raw))
  
}