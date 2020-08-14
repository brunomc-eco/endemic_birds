
# packages ----------------------------------------------------------------
library(raster)
library(dplyr)
library(progress)


# AF shapefile ------------------------------------------------------------
MA_shp <- shapefile('data/mask/mata_atlantica.shp')


# Buffer ------------------------------------------------------------------
MA_shp_buffer <- buffer(MA_shp, width = 5) # 'width = 5' is 5° buffer ≃ 555 km


# variables ---------------------------------------------------------------
files_list <- list.files('data/env/', pattern = "tif$|bil$", full.names = TRUE, recursive = TRUE)
files_name <- strsplit(files_list, split = "//") %>% sapply(function(x){x[2]})

dirs_list <- list.dirs('data/env/', recursive = F)
dirs_name <- strsplit(dirs_list, split = "//") %>% sapply(function(x){x[2]})

# creating dirs
for(path in dirs_name){
  if(!dir.exists(paste0("./data/env_croped/", path))) {
    dir.create(paste0("./data/env_croped/", path))
  }
}


# crop variables ----------------------------------------------------------
pb <- progress_bar$new(format = "(:spin) [:bar] :percent :elapsed layer: :current", total = length(files_list))
for(i in 1:length(files_list)){
  pb$tick()
  files_name[i] <- gsub(x = files_name[i], pattern = ".bil$", ".tif")
  files_list[i] %>%
    raster() %>%
    crop(MA_shp_buffer) %>%
    mask(mask = MA_shp_buffer) %>%
    writeRaster(filename = paste0("./data/env_croped/", files_name[i]))
}


# select uncorrelated variables -------------------------------------------

# list of files of present variables
present_list <- list.files("data/env_croped/present/", pattern = "tif$", full.names = T)

# object with present variables
present_ras <- stack(present_list)

# id from cells without NA
mi <- Which(present_ras[[1]], cells = TRUE)

# sampling cells to extract values
sampled <- sample(mi, 5000)

# values of selected cells from rasters of present variables
vals <- present_ras[sampled]

# selecting variables to exclude with correlation 0.6 or more
exclude_vars <- caret::findCorrelation(cor(vals, method = 'spearman'), cutoff = 0.6, names = TRUE)

# selecting variables with lower correlation (<0.6)
pres_vars_sel <- present_ras[[which(!names(present_ras) %in% exclude_vars)]]
pres_vars_sel

# selecting variables with lower correlation (<0.6)
pres_vars_sel_names <- names(present_ras)[!names(present_ras) %in% exclude_vars]
pres_vars_sel_names

# sample = 50000 and cutoff = 0.6
# "bio_10" "bio_16" "bio_18" "bio_19" "bio_2"  "bio_7"

# copy selected variables -------------------------------------------------

library(dplyr)
list_files_env <- list.files("data/env_croped/", pattern = "tif$", recursive = TRUE, full.names = TRUE)

list_dirs_env <- list.dirs("data/env_croped/", full.names = TRUE)

vars_sel <- c("bio_10", "bio_16", "bio_18", "bio_19", "bio_2", "bio_7")

vars_sel_pattern <-
  vars_sel %>%
  gsub(x = ., pattern = "bio_", "") %>%
  paste0("0", ., ".tif$", collapse = "|") %>%
  paste(paste0(vars_sel, collapse = "|"), collapse = "|", sep = "|")

vars_sel_pattern

list_sel <- grep(x = list_files_env, pattern = vars_sel_pattern, value = TRUE)
list_sel

list_sel_names <- strsplit(list_sel, split = "//") %>% sapply(FUN = function(x){x[2]})
list_sel_names

# creating dirs
for(path in dirs_name){
  if(!dir.exists(paste0("./data/env_sel/", path))) {
    dir.create(paste0("./data/env_sel/", path))
  }
}

# copiando os arquivos
file.copy(from = list_sel, to = paste0("data/env_sel/", list_sel_names), overwrite = TRUE)

# conferindo
list.files('data/env_sel/', recursive = TRUE)

