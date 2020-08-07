# spThin test
# Bruno M. Carvalho
# brunomc.eco@gmail.com

library(spThin)
library(tidyverse)
library(data.table)


# loading clean df
clean_df <- read_csv("./outputs/02_clean_df.csv")


# getting clean species list
spp <- sort(unique(clean_df$species))


# thinning records by 5 km
thin_5 <- list()
for(i in 1:length(spp)){
  df <- clean_df %>%
    filter(species %in% spp[i])
  thinned <- thin(df,
                  lat.col = "lat",
                  long.col = "lon",
                  spec.col = "species",
                  thin.par = 5, # distance in km
                  reps = 1,
                  locs.thinned.list.return = TRUE,
                  write.files = FALSE,
                  write.log.file = FALSE)
  thin_5[[i]] <- data.frame(species = rep(spp[i], nrow(thinned[[1]])),
                            lon = thinned[[1]]$Longitude,
                            lat = thinned[[1]]$Latitude)
}
clean_df_thin_5 <- rbindlist(thin_5)


# thinning records by 10 km
thin_10 <- list()
for(i in 1:length(spp)){
  df <- clean_df %>%
    filter(species %in% spp[i])
  thinned <- thin(df,
                  lat.col = "lat",
                  long.col = "lon",
                  spec.col = "species",
                  thin.par = 10, # distance in km
                  reps = 1,
                  locs.thinned.list.return = TRUE,
                  write.files = FALSE,
                  write.log.file = FALSE)
  thin_10[[i]] <- data.frame(species = rep(spp[i], nrow(thinned[[1]])),
                            lon = thinned[[1]]$Longitude,
                            lat = thinned[[1]]$Latitude)
}
clean_df_thin_10 <- rbindlist(thin_10)


# check thinned records
#ggplot() +
#  borders("world", colour="gray50", fill="gray50") +
#  geom_point(data = clean_df_thin_5, aes(x = lon, y = lat),
#             colour = "blue", size = 1.5) +
#  geom_point(data = clean_df_thin_10, aes(x = lon, y = lat),
#             colour = "red", size = 1.0) +
#  coord_sf(xlim = c(-109, -28), ylim = c(-55, 15)) +
#  theme_bw()


# counting records by species
n_5 <- clean_df_thin_5 %>%
  group_by(species) %>%
  summarize(n_thin_5 = n())

n_10 <- clean_df_thin_10 %>%
  group_by(species) %>%
  summarize(n_thin_10 = n())


# adding counts to the n_records table
n_records <- read_csv("./outputs/02_n_records.csv")

n_records <- n_records %>%
  left_join(n_5, by = "species") %>%
  left_join(n_10, by = "species") %>%
  replace_na(list(n_thin_5 = 0, n_thin_10 = 0))


# writing outputs
write_csv(n_records, path = "./outputs/03_n_thinned_records.csv")
write_csv(clean_df_thin_5, path = "./outputs/03_clean_df_thin_5.csv")
write_csv(clean_df_thin_10, path = "./outputs/03_clean_df_thin_10.csv")
