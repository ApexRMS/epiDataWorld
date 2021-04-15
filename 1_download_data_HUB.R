# HUB ---------------------------------------------------------------------

library(rsyncrosim)
library(COVID19)
E <- ssimEnvironment()
TRANSFORMER_NAME <- "Download COVID-19 Data Hub"

# Source helpers ----------------------------------------------------------

source(file.path(E$PackageDirectory, "0_epiDataWorld_env.R"))
source(file.path(E$PackageDirectory, "0_epiDataWorld_functions.R"))
source(file.path(E$PackageDirectory, "0_CovidHUB_functions.R"))
source(file.path(E$PackageDirectory, "0_JHU_functions.R"))

# Load data

inputs <- load_inputs(backend = "HUB", mySce = SCE, e = E)

# Save to epi

save_to_epi(dataSubset = inputs$covidDataSubset, mySce = SCE, vars = VARS)

# Process data and save it

covidDataFinal <- process_data(vars = VARS, covidDataSubset = inputs$covidDataSubset) %>% 
  mutate(TransformerID = TRANSFORMER_NAME)
saveDatasheet(SCE, covidDataFinal, "epi_DataSummary")

# Write out data

fileName <- make_filename(inputs_vars = inputs$input_vars)
filePath <- file.path(E$TransferDirectory, fileName)

write.csv(covidDataFinal, filePath, row.names = FALSE)

# Save outpout

save_output_info(mySce = SCE, input_vars = inputs$input_vars, backend = "HUB", filePath = filePath)
