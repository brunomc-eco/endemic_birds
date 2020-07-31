# spThin test
# Bruno M. Carvalho
# brunomc.eco@gmail.com

library(spThin)

records <- read_csv("./outputs/02_n_records.csv")

clean_df <- read_csv("./outputs/02_clean_df.csv")

spp <- sort(unique(clean_df$species))
spp1 <- spp[1:28]
spp2 <- spp[29:56]
spp3 <- spp[57:84]

spp1_df <- clean_df %>%
  filter(species %in% spp1)

spp2_df <- clean_df %>%
  filter(species %in% spp2)

spp3_df <- clean_df %>%
  filter(species %in% spp3)


thin_df_5 <- thin(spp1_df,
                  lat.col = "lat",
                  long.col = "lon",
                  spec.col = "species",
                  thin.par = 5,
                  reps = 1,
                  write.files = TRUE,
                  max.files = 1,
                  out.dir = "./outputs/",
                  out.base = "thinned_5km")

