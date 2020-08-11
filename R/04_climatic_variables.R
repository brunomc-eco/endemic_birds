
# packages ----------------------------------------------------------------
library(raster)
library(dplyr)


# AF shapefile ------------------------------------------------------------
MA_shp <- shapefile('data/mask/mata_atlantica.shp')


# Buffer ------------------------------------------------------------------
MA_shp_buffer <- buffer(MA_shp, width = 5) # 'width = 5' is 5° buffer ≃ 555 km


# variables ---------------------------------------------------------------
files_list <- list.files('data/env/', pattern = "tif$", full.names = TRUE, recursive = TRUE)
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
pb <- progress::progress_bar$new(format = "(:spin) [:bar] :percent :elapsed layer: :current", total = length(files_list))
for(i in 1:length(files_list)){
  pb$tick()
  files_list[i] %>%
    raster() %>%
    crop(MA_shp_buffer) %>%
    mask(mask = MA_shp_buffer) %>%
    writeRaster(filename = paste0("./data/env_croped/", files_name[i]))
}

