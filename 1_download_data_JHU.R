# JHU ---------------------------------------------------------------------

library(rsyncrosim)
E <- ssimEnvironment()
TRANSFORMER_NAME <- "Download Johns Hopkins University Data"

# Source helpers ----------------------------------------------------------

source(file.path(E$PackageDirectory, "0_epiDataWorld_env.R"))
source(file.path(E$PackageDirectory, "0_epiDataWorld_functions.R"))
source(file.path(E$PackageDirectory, "0_CovidHUB_functions.R"))
source(file.path(E$PackageDirectory, "0_JHU_functions.R"))

# 1. Load data

inputs <- load_inputs(backend = "JHU", mySce = SCE, e = E)

# 2. Save to epi

save_to_epi(dataSubset = inputs$covidDataSubset, mySce = SCE, vars = VARS)

# 3. Process data and save it

covidDataFinal <- process_data(vars = VARS, covidDataSubset = inputs$covidDataSubset) %>% 
  mutate(TransformerID = TRANSFORMER_NAME)
saveDatasheet(SCE, covidDataFinal, "epi_DataSummary")

# 4. Write out data

fileName <- make_filename(inputs_vars = inputs$input_vars)
filePath <- file.path(E$TransferDirectory, fileName)

write.csv(covidDataFinal, filePath, row.names = FALSE)

# 5. Save outpout

save_output_info(mySce = SCE, input_vars = inputs$input_vars, backend = "JHU", filePath = filePath)
