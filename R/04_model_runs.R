# ENM of target species
# Bruno M. Carvalho
# brunomc.eco@gmail.com

library(tidyverse)
library(raster)
library(rgdal)
library(modleR)


# reading species data
target_species <- read_csv("./data/target_species.csv") %>%
  filter(target_species == 1) %>%
  pull(species)

clean_df <- read_csv("./outputs/03_clean_df_thin_10.csv") %>%
  filter(species %in% target_species) # retaining only records from target species

# converting species names and data.frame for modleR
clean_df$species <- str_replace(clean_df$species, " ", "_")
target_species <- str_replace(target_species, " ", "_")
clean_df <- data.frame(species = clean_df$species,
                       lon = clean_df$lon,
                       lat = clean_df$lat)

# reading climatic data
wc <- list.files("./data/var/current/", pattern = "asc", full.names = TRUE) %>%
  stack()

# reading atlantic Forest mask
ma_mask <- readOGR("./data/mask/mata_atlantica.shp", layer = "mata_atlantica")

#i=1 # for testing the species loop


for(i in 1:length(target_species)){
  # setup data for ENM

  species_df <- clean_df[clean_df$species == target_species[i], ] # getting only occurrences for this species

  setup_sdmdata(species_name = target_species[i],
                occurrences = species_df,
                predictors = wc, # set of predictors for running the models
                models_dir = "./outputs/models", # folder to save partitions
                seed = 123, # set seed for random generation of pseudoabsences
                buffer_type = "maximum", # buffer type for sampling pseudoabsences, see help for types
                #env_filter = TRUE, # exclusion buffer for pseudoabsences sensu Varella et al 2014
                #min_env_dist = 0.05, # minimum distance to environmental centroid, in quantiles, to exclude from pseudoabsence sampling buffer (default = 0.05)
                clean_dupl = TRUE, # remove duplicate records
                clean_nas = TRUE, # remove records with na values from variables
                clean_uni = TRUE, # remove records falling at the same pixel
                select_variables = FALSE, # select variables by correlation
                #cutoff = 0.8, # correlation threshold for variable selection
                #sample_proportion = 0.5 #proportion of raster pixels to be sampled for correlations
                png_sdmdata = TRUE, # save minimaps in png
                n_back = 1000, # number of pseudoabsences
                partition_type = "crossvalidation",
                cv_partitions = 5, # number of folds for crossvalidation
                cv_n = 1) # number of crossvalidation runs

  # run selected algorithms for each partition
  do_many(species_name = target_species[i],
          predictors = wc,
          models_dir = "./outputs/models",
          project_model = TRUE, # project models into other sets of variables
          proj_data_folder = "./data/var/future", # folder with projection variables
          mask = ma_mask, # mask for projecting the models
          png_partitions = FALSE, # save minimaps in png?
          write_bin_cut = TRUE, # save binary and cut outputs?
          dismo_threshold = "spec_sens", # threshold rule for binary outputs
          equalize = TRUE, # equalize numbers of presence and pseudoabsences for random forest,
          bioclim = TRUE,
          glm = TRUE,
          maxent = TRUE,
          rf = TRUE,
          svmk = TRUE)

  #combine partitions into one final model per algorithm
  final_model(species_name = target_species[i],
              models_dir = "./outputs/models",
              which_models = c("raw_mean", "bin_consensus"),
              consensus_level = 0.5, # proportion of models in the binary consensus
              png_final = TRUE,
              overwrite = TRUE)

  #generate ensemble models, combining final models from all algorithms
  ensemble_model(species_name = target_species[i],
                 occurrences = species_df,
                 models_dir = "./outputs/models",
                 performance_metric = "TSSmax",
                 which_ensemble = c("weighted_average", "consensus"),
                 which_final = "raw_mean",
                 consensus_level = 0.5,
                 png_ensemble = TRUE,
                 uncertainty = TRUE,
                 overwrite = TRUE)

  # To do: include here deleting unnecessary files?

}
