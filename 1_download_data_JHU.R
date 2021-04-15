# JHU ---------------------------------------------------------------------

library(rsyncrosim)
E <- ssimEnvironment()
TRANSFORMER_NAME <- "DownloadJHU"

# Source helpers ----------------------------------------------------------

source(file.path(E$PackageDirectory, "0_epiDataWorld_env.R"))
source(file.path(E$PackageDirectory, "0_epiDataWorld_functions.R"))
source(file.path(E$PackageDirectory, "0_CovidHUB_functions.R"))
source(file.path(E$PackageDirectory, "0_JHU_functions.R"))

# Load data

inputs <- load_inputs("JHU", SCE, E)

# Save to epi

save_to_epi(inputs$covidDataSubset, SCE, VARS)

# Process data and save it

covidDataFinal <- process_data(VARS, inputs$covidDataSubset) %>% 
  mutate(TransformerID = TRANSFORMER_NAME)
saveDatasheet(SCE, covidDataFinal, "epi_DataSummary")

# Write out data

fileName <- make_filename(inputs$inputs)
filePath <- file.path(E$TransferDirectory, fileName)

write.csv(covidDataFinal, filePath, row.names = FALSE)

# Save outpout

save_output_info(SCE, inputs$input_vars, "JHU", filePath)
