# Cleaning records
# Bruno M. Carvalho
# brunomc.eco@gmail.com

library(tidyverse)
library(CoordinateCleaner)
library(countrycode)

# reading data
Hasui_df <- read_csv("./outputs/01_unclean_records_Hasui.csv")
gbif_df <- read_csv("./outputs/01_unclean_records_gbif.csv")
splist <- read_csv("./data/splist.csv", col_names = FALSE)
splist <- as.character(splist$X1)
only_keys <- read_csv("./outputs/01_gbif_taxonkeys.csv")
only_keys <- as.character(only_keys$taxonKey)

# removing records with NA coordinates, keeping only species from our list
Hasui_occs <- Hasui_df %>%
  filter(!is.na(Longitude_x) & !is.na(Latitude_y)) %>%
  filter(Species %in% splist)

gbif_occs <- gbif_df %>%
  filter(!is.na(decimalLongitude) & !is.na(decimalLatitude)) %>%
  filter(taxonKey %in% only_keys)

# Viewing unclean records
#ggplot()+ coord_fixed()+
#  borders("world", colour="gray50", fill="gray50") +
#  geom_point(data = gbif_occs, aes(x = decimalLongitude, y = decimalLatitude),
#             colour = "yellow", size = 0.5)+
#  geom_point(data = Hasui_occs, aes(x = Longitude_x, y = Latitude_y),
#             colour = "darkred", size = 0.5)+
#  theme_bw()


# standardizing country names
gbif_occs$countryCode <- countrycode(gbif_occs$countryCode, origin = 'iso2c', destination = 'iso3c')
Hasui_occs$Country <- countrycode(Hasui_occs$Country, origin = 'country.name', destination = 'iso3c')

# cleaning data with CoordinateCleaner
flags_gbif <- clean_coordinates(x = gbif_occs,
                                lon = "decimalLongitude",
                                lat = "decimalLatitude",
                                countries = "countryCode",
                                centroids_rad = 2000, # had to increase this limit because was not flagging the centroid of Brazil
                                species = "scientificName",
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
# filter out very old records?

# Merging clean datasets
Hasui_clean <- tibble(species = Hasui_clean1$Species,
                      #year = Hasui_clean1$Year,
                      lon = Hasui_clean1$Longitude_x,
                      lat = Hasui_clean1$Latitude_y,
                      source = rep("Hasui", nrow(Hasui_clean1)))

gbif_clean <- tibble(species = gbif_clean1$species,
                      #year = gbif_clean1$year,
                      lon = gbif_clean1$decimalLongitude,
                      lat = gbif_clean1$decimalLatitude,
                      source = rep("gbif", nrow(gbif_clean1)))

clean_df <- bind_rows(Hasui_clean, gbif_clean)

# removing duplicates
clean_df <- clean_df %>%
  distinct()

# which species have records in the western part of South America? (lon < -65)

western_species <- clean_df %>%
  mutate(western = lon <= -65) %>%
  filter(western == TRUE) %>%
  #group_by(species, western) %>%
  #summarize(n_records = n()) %>%
  pull(species) %>%
  unique() %>%
  tibble() %>%
  rename("westernmost_species" = ".") %>%
  arrange(westernmost_species)


# removing these species from clean_df
`%notin%` <- Negate(`%in%`)

clean_df <- clean_df %>%
  filter(species %notin% as.character(western_species$westernmost_species))


# plotting clean records
ggplot() +
  borders("world", colour="gray50", fill="gray50") +
  geom_point(data = clean_df, aes(x = lon, y = lat),
             colour = "blue", size = 0.5) +
  coord_sf(xlim = c(-109, -28), ylim = c(-55, 15)) +
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


# writing outputs

write_csv(n_records, path = "./outputs/02_n_records.csv")
write_csv(clean_df, path = "./outputs/02_clean_df.csv")
write_csv(western_species, path = "./outputs/02_westernmost_species_gbif.csv")
