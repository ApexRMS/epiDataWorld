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

VARS <- c("Cases - Daily", "Cases - Cumulative")
