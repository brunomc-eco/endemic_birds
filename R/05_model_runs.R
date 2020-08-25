# ENM of target species
# Bruno M. Carvalho <brunomc.eco@gmail.com>
# Diogo S. B. Rocha <diogosbr@gmail.com>

# loading packages
library(dplyr)
library(raster)
library(progress)
library(modleR)
library(foreach)

# reading species data
target_species <- read.csv("./data/target_species.csv", stringsAsFactors = FALSE) %>%
  filter(target_species == 1) %>%
  pull(species)

clean_df <- read.csv("./outputs/03_clean_df_thin_10.csv", stringsAsFactors = FALSE) %>%
  filter(species %in% target_species) # retaining only records from target species

# converting species names for modleR
clean_df$species <- gsub(x = clean_df$species, pattern = " ", replacement = "_")
target_species <- gsub(x = target_species, pattern = " ", replacement = "_")

# reading climatic data
wc <- list.files("./data/env_sel/present/", pattern = "tif$", full.names = TRUE) %>%
  stack()


# loops for ENM ----------------------------------------------------------------

# parallelism
cl = snow::makeCluster(11, outfile = 'outputs/models/out.log')
doSNOW::registerDoSNOW(cl)

# creating progress bar
pb <- progress_bar$new(
  format = "(:spin) [:bar] :percent :elapsed sp: :current",
  total = length(target_species), clear = FALSE)

# setting Progress Bar
progress_number = 1:length(target_species)
progress = function(n){pb$tick(tokens = list(sp = progress_number[n]))}
opts <- list(progress =  progress)

# setup data
#for(sp in target_species){
#pb$tick()
temp <-
  foreach(sp = target_species, .inorder = FALSE,
          .packages = c("modleR", "progress"),
          .options.snow = opts) %dopar% {

            species_df <- clean_df[clean_df$species == sp, ] # getting only occurrences for this species

            # choosing the type of partition depending on the number of records
            partition_type <- ifelse(nrow(species_df) > 50, "crossvalidation", "bootstrap")

            setup_sdmdata(species_name = sp,
                          occurrences = species_df,
                          predictors = wc, # set of predictors for running the models
                          models_dir = "./outputs/models_buffertype_NULL_envdist_FALSE_10000", # folder to save partitions
                          seed = 123, # set seed for random generation of pseudoabsences
                          buffer_type = NULL, # buffer type for sampling pseudoabsences

                          # env_filter = TRUE,
                          # env_distance = "centroid",
                          # min_env_dist = 0.1,

                          clean_dupl = TRUE, # remove duplicate records
                          clean_nas = TRUE, # remove records with na values from variables
                          clean_uni = TRUE, # remove records falling at the same pixel
                          png_sdmdata = TRUE, # save minimaps in png
                          n_back = nrow(species_df) * 10, # number of pseudoabsences
                          partition_type = partition_type,
                          cv_partitions = 10, # number of folds for crossvalidation
                          cv_n = 1,# number of crossvalidation runs
                          boot_n = 10, # number of crossvalidation runs
                          boot_proportion = 0.1) # number of partitions in the crossvalidation
          }

snow::stopCluster(cl)

# partitions
temp <-
  foreach::foreach(sp = target_species, .inorder = FALSE,
                   .packages = c("modleR", "progress"),
                   .options.snow = opts) %dopar% {
                     # for(sp in target_species){
                     #   pb$tick()

                     # run selected algorithms for each partition
                     do_many(species_name = sp,
                             predictors = wc,
                             models_dir = "./outputs/models_buffertype_NULL_envdist_FALSE_10000",
                             project_model = TRUE, # project models into other sets of variables
                             proj_data_folder = "./data/env_sel/future/", # folder with projection variables
                             #mask = ma_mask, # mask for projecting the models
                             png_partitions = TRUE, # save minimaps in png?
                             write_bin_cut = TRUE, # save binary and cut outputs?
                             dismo_threshold = "spec_sens", # threshold rule for binary outputs
                             equalize = TRUE, # equalize numbers of presence and pseudoabsences for random forest and brt
                             bioclim = TRUE,
                             glm = TRUE,
                             maxent = TRUE,
                             rf = TRUE,
                             svmk = TRUE,
                             brt = TRUE)
                   }
snow::stopCluster(cl)

# final_models
for(sp in target_species){
  pb$tick()

  #combine partitions into one final model per algorithm
  final_model(species_name = sp,
              models_dir = "./outputs/models",
              #algorithms = c("bioclim", "glm", "maxent", "rf", "svmk", "brt"),
              which_models = c("raw_mean", "bin_consensus"),
              consensus_level = 0.5, # proportion of models in the binary consensus
              png_final = TRUE,
              overwrite = TRUE)
}

# ensemble models
for(sp in target_species){
  pb$tick()

  #generate ensemble models, combining final models from all algorithms
  ensemble_model(species_name = target_species[i],
                 #algorithms = c("bioclim", "glm", "maxent", "rf", "svmk", "brt"),
                 occurrences = species_df,
                 models_dir = "./outputs/models",
                 performance_metric = "TSSmax",
                 which_ensemble = c("weighted_average", "consensus"),
                 which_final = "raw_mean",
                 consensus_level = 0.5,
                 png_ensemble = TRUE,
                 uncertainty = TRUE,
                 overwrite = TRUE)
}
