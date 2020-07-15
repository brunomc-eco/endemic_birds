# Getting species records from Hasui et al 2018

library(tidyverse)

# reading species data from paper
s1_qual <- read.csv("./data/DataS1_Hasui/ATLANTIC_BIRDS_qualitative.csv")
s1_quan <- read.csv("./data/DataS1_Hasui/ATLANTIC_BIRDS_quantitative.csv")
s1_species <- read.csv("./data/DataS1_Hasui/ATLANTIC_birds_species.csv")

# reading our species list (107 spp.)
splist <- read.delim("./data/splist.txt", header = FALSE)

# binding data, keeping only records of species from our list
df <- bind_rows(s1_qual, s1_quan) %>%
  filter(Species %in% splist)

# which species were not in Hasui et al data?
spp <- df %>%
  distinct(Species)

not_in_hasui <- splist[!splist %in% spp$Species]


# getting records from gbif - got this from https://data-blog.gbif.org/post/downloading-long-species-lists-on-gbif/

library(rgbif)
library(taxize)
library(purrr)

gbif_taxon_keys <- splist %>%
  get_gbifid_(method="backbone") %>% # get taxonkeys for each species name
  imap(~ .x %>% mutate(original_sciname = .y)) %>% # add original name back to data.frame
  bind_rows() # combine all results in a single data.frame

only_keys <- gbif_taxon_keys %>%
  filter(matchtype == "EXACT" & status == "ACCEPTED") %>% # get only accepted names
  pull(usagekey) #retain only the taxonkeys


occ_download(
  pred_in("taxonKey", only_keys),
  format = "SIMPLE_CSV",
  user="brunomc",pwd="crazy1986",email="brunomc.eco@gmail.com"
)

# which species were not found on gbif?
matched_species <- gbif_taxon_keys %>%
  filter(matchtype == "EXACT" & status == "ACCEPTED") %>% # get only accepted names
  pull(original_sciname)

not_in_gbif <- splist[!splist %in% matched_species]


# explore data downloaded from gbif
occs <- read.csv("./data/data_gbif/0022508-200613084148143.csv", header=TRUE)
