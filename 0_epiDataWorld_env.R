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
          "Deaths - Cumulative", "Deaths - Daily")
