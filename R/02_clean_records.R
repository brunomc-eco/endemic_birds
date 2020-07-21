# Cleaning records
# Bruno M. Carvalho
# brunomc.eco@gmail.com

library(tidyverse)
library(CoordinateCleaner)

# reading data
Hasui_df <- read_csv("./outputs/01_unclean_records_Hasui.csv")
gbif_df <- read_csv("./outputs/01_unclean_records_gbif.csv")
splist <- read_csv("./data/splist.csv", col_names = FALSE)
splist <- as.character(splist$X1)

# removing records with NA coordinates, keeping only species from our list
Hasui_occs <- Hasui_df %>%
  filter(!is.na(Longitude_x) & !is.na(Latitude_y)) %>%
  filter(Species %in% splist)

gbif_occs <- gbif_df %>%
  filter(!is.na(decimalLongitude) & !is.na(decimalLatitude)) %>%
  filter(species %in% splist)


# Viewing unclean records
world <- borders("world", colour="gray50", fill="gray50")
sa <- borders("world", colour="gray50", fill="gray50", xlim = c(-109, -28), ylim = c(-55, 15))

ggplot()+ coord_fixed()+ world +
  geom_point(data = gbif_occs, aes(x = decimalLongitude, y = decimalLatitude),
             colour = "yellow", size = 0.5)+
  geom_point(data = Hasui_occs, aes(x = Longitude_x, y = Latitude_y),
             colour = "darkred", size = 0.5)+
  theme_bw()

ggplot()+ coord_fixed()+ sa +
  geom_point(data = gbif_occs, aes(x = decimalLongitude, y = decimalLatitude),
             colour = "yellow", size = 0.5)+
  geom_point(data = Hasui_occs, aes(x = Longitude_x, y = Latitude_y),
             colour = "darkred", size = 0.5)+
  theme_bw()


# cleaning data with CoordinateCleaner
flags_gbif <- clean_coordinates(x = gbif_occs,
                                lon = "decimalLongitude",
                                lat = "decimalLatitude",
                                countries = "countryCode",
                                species = "species",
                                tests = c("capitals", # flags records at adm-0 capitals
                                          "centroids", # flags records at country centroids
                                          "equal", # flags records with equal lon and lat
                                          "gbif", # flags records at gbif headquarters
                                          "institutions", # flags records at biodiversity institutions
                                          "seas", # flags records at sea
                                          "zeros")) # flags records with zero lon or lat

flags_Hasui <- clean_coordinates(x = Hasui_occs,
                                 lon = "Longitude_x",
                                 lat = "Latitude_y",
                                 species = "Species",
                                 tests = c("capitals", "centroids", "equal", "gbif", "institutions", "seas", "zeros"))

# viewing flagged records
# plot(flags_gbif, lon = "decimalLongitude", lat = "decimalLatitude")
# plot(flags_Hasui, lon = "Longitude_x", lat = "Latitude_y")


# Removing flagged records and duplicates
gbif_clean1 <- gbif_occs[flags_gbif$.summary, ] %>%
  distinct()

Hasui_clean1 <- Hasui_occs[flags_Hasui$.summary, ] %>%
  distinct()


#### etc: include here other cleaning routines


# Merging clean datasets
Hasui_clean <- tibble(species = Hasui_clean1$Species,
                      year = Hasui_clean1$Year,
                      lon = Hasui_clean1$Longitude_x,
                      lat = Hasui_clean1$Latitude_y,
                      source = rep("Hasui", nrow(Hasui_clean1)))

gbif_clean <- tibble(species = gbif_clean1$species,
                      year = gbif_clean1$year,
                      lon = gbif_clean1$decimalLongitude,
                      lat = gbif_clean1$decimalLatitude,
                      source = rep("gbif", nrow(gbif_clean1)))

clean_df <- bind_rows(Hasui_clean, gbif_clean)

# removing duplicates
clean_df <- clean_df %>%
  distinct()


# plotting clean records
ggplot()+ coord_fixed()+ sa +
  geom_point(data = clean_df, aes(x = lon, y = lat),
             colour = "blue", size = 0.5)+
  theme_bw()

# write n_records table
n_records <- read_csv("./outputs/01_search_results.csv")
count_Hasui <- count(Hasui_clean, species)
count_gbif <- count(gbif_clean, species)
count_merged <- count(clean_df, species)

n_records <- n_records %>%
  left_join(count_Hasui, by = "species") %>%
  rename(Hasui_clean1 = n) %>%
  left_join(count_gbif, by = "species") %>%
  rename(gbif_clean1 = n) %>%
  left_join(count_merged, by = "species") %>%
  rename(merged_clean1 = n) %>%
  replace_na(list(Hasui_clean1 = 0, gbif_clean1 = 0, merged_clean1 = 0))

write_csv(n_records, path = "./outputs/02_n_records.csv")
write_csv(clean_df, path = "./outputs/02_clean_df.csv")

#### TO DO LIST ####

# filter records by time frame (years?)
# filter records outside Atlantic Forest + buffer??
