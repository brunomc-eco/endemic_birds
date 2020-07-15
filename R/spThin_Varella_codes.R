# Aiello‐Lammens et al. (2015). spThin: an R package for spatial 
# thinning of species occurrence records for use in ecological niche models.
# Ecography 38: 541–545, doi: 10.1111/ecog.01132

library( spThin )
setwd("directory")

# Conferir como estao escritos "lat" e "lon" na tabela e colocar o nome exato ai embaixo
# "thin.par" eh onde coloca quantos km se quer usar, a gente usa 1km

thinned_dataset_full <-
  thin( loc.data = tina_soli_sdupl, 
        lat.col = "lat", long.col = "lon", 
        spec.col = "Species", 
        thin.par = 1, reps = 1, 
        locs.thinned.list.return = TRUE, 
        write.files = TRUE, 
        max.files = 1, 
        out.dir = ".", out.base = "species_name", 
        write.log.file = F)

# Se eu nao me engano, salva com essa terminacao "_thin1"
sp <- read.csv("directory/species_name_thin1.csv",sep=",")
dim(sp)


# From https://github.com/SaraVarela/envSample
# Varela, S., Anderson, R.P., Garcia-Valdes, R., Fernandez-Gonzalez, F., 2014. 
# Environmental filters reduce the effects of sampling bias 
# and improve predictions of ecological niche models. Ecography 37, 1084-1091.

library(rgdal)
library(roxygen2)
library(sqldf)
library(testthat)
library(dplyr)

# Data format

sp <- read.table("directory/species.csv",header=TRUE, sep=",")
head(sp)
names(sp) <- c("species","lon","lat")
Species <- sp[,2:3] #a tabela que entra abaixo eh so com lon e lat

# Ler os rasters que vão ser usados
environment <- stack(Bio1, Bio2, Bio3, Bio4)
# Lembrar que se mudar o nome das variáveis vai ter que mudar aqui abaixo e na funcao
names(environment) <- c("Bio1","Bio2","Bio3","Bio4")



# Function to clean the environmental bias

envSample<- function (coord, filters, res, do.plot=TRUE){
  
  n<- length (filters)
  pot_points<- list ()
  for (i in 1:n){
    k<- filters [[i]] [!is.na(filters[[i]])]
    ext1<- range (k)
    ext1 [1]<- ext1[1]- 1
    x<- seq(ext1[1],ext1[2], by=res[[i]])
    pot_points[[i]]<- x
  }
  pot_p<- expand.grid(pot_points)
  
  ends<- NULL
  for (i in 1:n){
    fin<- pot_p [,i] + res[[i]]
    ends<- cbind (ends, fin)
  }
  
  pot_pp<- data.frame (pot_p, ends)
  pot_pp<- data.frame (pot_pp, groupID=c(1:nrow (pot_pp)))
  rows<- length (filters[[1]])
  filter<- data.frame(matrix(unlist(filters), nrow=rows))
  real_p<- data.frame (coord, filter)
  
  names_real<- c("lon", "lat")
  names_pot_st<- NULL
  names_pot_end<- NULL
  sql1<- NULL
  for (i in 1:n){
    names_real<- c(names_real, paste ("filter", i, sep=""))
    names_pot_st<- c(names_pot_st, paste ("start_f", i, sep=""))
    names_pot_end<- c(names_pot_end, paste ("end_f", i, sep=""))
    sql1<- paste (sql1, paste ("real_p.filter", i, sep=""), sep=", ")   
  }
  
  names (real_p)<- names_real
  names (pot_pp)<- c(names_pot_st, names_pot_end, "groupID")
  
  conditions<- paste ("(real_p.filter", 1, "<= pot_pp.end_f", 1,") and (real_p.filter", 1, "> pot_pp.start_f", 1, ")", sep="")
  for (i in 2:n){
    conditions<- paste (conditions, 
                        paste ("(real_p.filter", i, "<= pot_pp.end_f", i,") and (real_p.filter", i, "> pot_pp.start_f", i, ")", sep=""), 
                        sep="and")
  }
  
  selection_NA<- sqldf(paste ("select real_p.lon, real_p.lat, pot_pp.groupID",   
                              sql1, "from pot_pp left join real_p on", conditions, sep=" "))
  
  selection<- selection_NA [complete.cases(selection_NA),]
  
  final_points<- selection[!duplicated(selection$groupID), ]
  coord_filter<- data.frame (final_points$lon, final_points$lat) 
  names (coord_filter)<- c("lon", "lat")
  
  if (do.plot==TRUE){
    par (mfrow=c(1,2), mar=c(4,4,0,0.5))
    plot (filters[[1]], filters[[2]], pch=19, 
          col="grey50", xlab="Filter 1", ylab="Filter 2")
    points (final_points$filter1, final_points$filter2, 
            pch=19, col="#88000090")
    plot (coord, pch=19, col="grey50")
    map(add=T)
    points (coord_filter, pch=19, col="#88000090")
    
  }
  coord_filter
}


env.data <- extract(environment, Species) 
env.data <- as.data.frame(env.data)

(Species.training <- envSample(Species, filters=list(env.data$Bio1, env.data$Bio2,
                                                     env.data$Bio3, env.data$Bio4), res=list(20, 20, 20, 20), do.plot=TRUE))


n_training <- as.numeric(dim(Species.training)[1])
sp_training = Species.training
sp_name <- rep("species_name", nrow(Species.training))
sp_training <- data.frame(sp_name,Species.training)
colnames(sp_training) <- c("species","lon","lat")
