# Environment -------------------------------------------------------------

# Load libraries
library(dplyr)
library(tidyr)
library(readr)
library(lubridate) 

# Load environment

LIB <- ssimLibrary()
SCE <- scenario()

# TRANSFER_DIR <- e$TransferDirectory

VARS <- c("Cases - Cumulative", "Cases - Daily", 
          "Recovered - Cumulative", "Recovered - Daily", 
          "Tested - Cumulative", "Tested - Daily",
          "Deaths - Cumulative", "Deaths - Daily", 
          "Vaccines - Cumulative", "Vaccines - Daily")
RAWVARS <- c("confirmed", "dailyconfirmed", 
             "recovered", "dailyrecovered", 
             "tested", "dailytested", 
             "deaths", "dailydeaths", 
             "vaccines", "dailyvaccines")
LOOKUP <- data.frame(VARS = VARS,
                     RAWVARS = RAWVARS)

OWDVARS <- VARS <- c("Cases - Cumulative", "Cases - Daily", 
                     "Deaths - Cumulative", "Deaths - Daily", 
                     "ICU patients - Cumulative", 
                     "Hospitalizations - Cumulative")
OWDRAWVARS <- c("total_cases", "new_cases", 
                "total_deaths", "new_deaths", 
                "icu_patients", 
                "hosp_patients")
OWDLOOKUP <- data.frame(VARS = OWDVARS,
                        RAWVARS = OWDRAWVARS)

JHU_BASE_URL <- paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/",
                       "master/csse_covid_19_data/csse_covid_19_time_series/")

HUB_URL <- "https://covid19datahub.io/articles/data.html"

OWD_URL <- "https://covid.ourworldindata.org/data/owid-covid-data.csv"
