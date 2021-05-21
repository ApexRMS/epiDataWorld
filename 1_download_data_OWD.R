# JHU ---------------------------------------------------------------------

library(rsyncrosim)
E <- ssimEnvironment()
TRANSFORMER_NAME <- "Download from Our World in Data"

# Source helpers ----------------------------------------------------------

source(file.path(E$PackageDirectory, "0_epiDataWorld_env.R"))
source(file.path(E$PackageDirectory, "0_epiDataWorld_functions.R"))
source(file.path(E$PackageDirectory, "0_OWD_functions.R"))

# 1. Load data

inputs <- load_inputs(backend = "OWD", mySce = SCE, e = E)

# 2. Save to epi

save_to_epi(dataSubset = inputs$covidDataSubset, mySce = SCE, vars = OWDVARS)

# 3. Process data and save it

covidDataFinal <- inputs$covidDataSubset %>% 
  mutate(TransformerID = TRANSFORMER_NAME) %>% 
  replace_na(list(Value = 0))
saveDatasheet(SCE, covidDataFinal, "epi_DataSummary", append = TRUE)

# 4. Write out data

fileName <- make_filename(inputs_vars = inputs$input_vars, backend = "OWD")
filePath <- file.path(E$TransferDirectory, fileName)

write.csv(inputs$raw, filePath, row.names = FALSE)

# 5. Save outpout

save_output_info(mySce = SCE, input_vars = inputs$input_vars, backend = "OWD", filePath = filePath)
