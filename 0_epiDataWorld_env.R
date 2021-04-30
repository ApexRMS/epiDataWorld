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
          "Active - Daily", # Active cases are daily by default
          "Recovered - Cumulative", "Recovered - Daily", 
          "Tested - Cumulative", "Tested - Daily",
          "Deaths - Cumulative", "Deaths - Daily", 
          "Vaccines - Cumulative", "Vaccines - Daily")
RAWVARS_HUB <- c("confirmed", "dailyconfirmed", 
                 NA, 
                 "recovered", "dailyrecovered", 
                 "tested", "dailytested", 
                 "deaths", "dailydeaths", 
                 "vaccines", "dailyvaccines")
RAWVARS_JHU <- NA
LOOKUP <- data.frame(VARS = VARS,
                     RAWVARS_HUB = RAWVARS_HUB, 
                     RAWVARS_JHU = RAWVARS_JHU)
