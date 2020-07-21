# Getting species records from Hasui et al 2018 and GBIF
# Bruno M. Carvalho
# brunomc.eco@gmail.com

library(tidyverse)
library(rgbif)
library(taxize)
library(data.table)

# reading our species list (107 spp.)
splist <- read_csv("./data/splist.csv", col_names = FALSE)
splist <- as.character(splist$X1)


# reading species data from Hasui
s1_qual <- read_csv("./data/DataS1_Hasui/ATLANTIC_BIRDS_qualitative.csv")
s1_quan <- read_csv("./data/DataS1_Hasui/ATLANTIC_BIRDS_quantitative.csv")
s1_species <- read_csv("./data/DataS1_Hasui/ATLANTIC_birds_species.csv")

# binding data, keeping only records of species from our list
Hasui_df <- bind_rows(s1_qual, s1_quan) %>%
  filter(Species %in% splist)


# getting records from gbif
# got this code from https://data-blog.gbif.org/post/downloading-long-species-lists-on-gbif/

gbif_taxon_keys <- splist %>%
  get_gbifid_(method="backbone") %>% # get taxonkeys for each species name
  imap(~ .x %>% mutate(original_sciname = .y)) %>% # add original name back to data.frame
  bind_rows() # combine all results in a single data.frame

only_keys <- gbif_taxon_keys %>%
  filter(matchtype == "EXACT" & status == "ACCEPTED") %>% # get only accepted names
  pull(usagekey) #retain only the taxonkeys

# download data directly at GBIF
# (file needs to be mannualy fetched at the user's downloads page at gbif.org)

# enter GBIF credentials
user = "username"
pwd = "password"
email = "e-mail"

occ_download(
  pred_in("taxonKey", only_keys),
  format = "SIMPLE_CSV",
  user = user, pwd = pwd, email = email
)

gbif_df <- fread("./data/data_gbif/0025885-200613084148143.csv", na.strings = c("", NA))

# table with search results

count_Hasui <- Hasui_df %>%
  count(Species)

count_gbif <- gbif_df %>%
  count(species)

searches <- tibble(species = splist, date_of_search = rep(Sys.Date(), length(splist))) %>%
  left_join(count_Hasui, by = c("species" = "Species")) %>%
  rename(Hasui_filtered = n) %>%
  left_join(count_gbif, by = "species") %>%
  rename(gbif_filtered = n) %>%
  replace_na(list(Hasui_filtered = 0, gbif_filtered = 0))


# saving outputs
write_csv(searches, "./outputs/01_search_results.csv")
write_csv(Hasui_df, "./outputs/01_unclean_records_Hasui.csv")
write_csv(gbif_df, "./outputs/01_unclean_records_gbif.csv")
