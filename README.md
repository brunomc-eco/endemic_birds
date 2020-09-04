---
output:
  pdf_document: default
  html_document: default
---
# Habitat amount is more important than climate change for landscape-scale bird conservation in a biodiversity hotspot

ENM of Atlantic Rainforest endemic birds

## Species list

A total of 14,965 records of 71 species. 
This table of records is from the `"./outputs/03_clean_df_thin_10.csv"` file. 

|   |spp                            | rec|
|:-:|:------------------------------|---:|
|1  |Amazona brasiliensis           |  39|
|2  |Amazona rhodocorytha           | 108|
|3  |Anabacerthia amaurotis         | 187|
|4  |Anabacerthia lichtensteini     | 343|
|5  |Anabazenops fuscus             | 257|
|6  |Arremon semitorquatus          | 186|
|7  |Automolus lammi                |  22|
|8  |Buteogallus lacernulatus       | 136|
|9  |Campephilus robustus           | 534|
|10 |Carpornis cucullata            | 259|
|11 |Cichlocolaptes leucophrus      | 224|
|12 |Conopophaga cearae             |  36|
|13 |Cotinga maculata               |  29|
|14 |Cranioleuca pallida            | 401|
|15 |Drymophila ferruginea          | 397|
|16 |Drymophila genei               |  76|
|17 |Drymophila ochropyga           | 289|
|18 |Drymophila rubricollis         | 214|
|19 |Dysithamnus xanthopterus       |  96|
|20 |Glaucis dohrnii                |  27|
|21 |Haplospiza unicolor            | 403|
|22 |Heliobletus contaminatus       | 330|
|23 |Hemitriccus obsoletus          | 155|
|24 |Hemitriccus orbitatus          | 317|
|25 |Hypoedaleus guttatus           | 104|
|26 |Ilicura militaris              | 399|
|27 |Jacamaralcyon tridactyla       |  69|
|28 |Leptodon forbesi               |  27|
|29 |Lipaugus lanioides             | 143|
|30 |Merulaxis ater                 | 117|
|31 |Mionectes rufiventris          | 610|
|32 |Myrmoderus loricatus           | 155|
|33 |Myrmotherula unicolor          | 174|
|34 |Myrmotherula urosticta         |  73|
|35 |Neopelma aurifrons             |  64|
|36 |Neopelma chrysolophum          | 140|
|37 |Notharchus swainsoni           | 144|
|38 |Odontophorus capueira          | 416|
|39 |Onychorhynchus swainsoni       |  46|
|40 |Phacellodomus erythrophthalmus | 197|
|41 |Phaethornis idaliae            |  57|
|42 |Philydor atricapillus          | 385|
|43 |Phyllomyias virescens          | 311|
|44 |Phylloscartes beckeri          |  23|
|45 |Phylloscartes difficilis       | 100|
|46 |Phylloscartes oustaleti        | 145|
|47 |Phylloscartes paulista         | 114|
|48 |Phylloscartes sylviolus        |  99|
|49 |Piculus aurulentus             | 438|
|50 |Picumnus temminckii            | 579|
|51 |Piprites pileata               |  88|
|52 |Platyrinchus leucoryphus       |  96|
|53 |Pseudastur polionotus          | 174|
|54 |Pteroglossus bailloni          | 245|
|55 |Pyriglena atra                 |  26|
|56 |Pyrrhura cruentata             |  69|
|57 |Ramphodon naevius              | 228|
|58 |Rhopias gularis                | 273|
|59 |Saltator fuliginosus           | 375|
|60 |Saltator maxillosus            | 204|
|61 |Schiffornis virescens          | 820|
|62 |Sclerurus scansor              | 507|
|63 |Scytalopus pachecoi            |  62|
|64 |Scytalopus speluncae           | 255|
|65 |Terenura maculata              | 277|
|66 |Thamnophilus ambiguus          | 235|
|67 |Thlypopsis pyrrhocoma          | 296|
|68 |Tinamus solitarius             | 315|
|69 |Touit melanonotus              |  79|
|70 |Touit surdus                   |  89|
|71 |Xipholena atropurpurea         |  58|


## Modeling parameters 

### Variables (worldclim)

#### from the new selection (with cutoff = 0.6)
- BIO2 = Mean Diurnal Range (Mean of monthly (max temp - min temp))
- BIO7 = Temperature Annual Range (BIO5-BIO6)
- BIO10 = Mean Temperature of Warmest Quarter
- BIO16 = Precipitation of Wettest Quarter
- BIO18 = Precipitation of Warmest Quarter
- BIO19 = Precipitation of Coldest Quarter

### Future year

- 2050

### GCMs (from worldclim)

- ACCESS1-0
- HadGEM2-ES
- MPI-ESM-LR

### Representative Concentration Pathway

- RCP 8.5

### Resolution 

- 30 arc-sec

### Study area

- Atlantic Forest with 5° (≃555km) buffer

### Algorithms

- Bioclim
- Maxent
- GLM
- RandomForest
- SVM

### Pseudoabsences (PA)

*Inclusion criteria* is the median relative geographical distance between the points of presence themselves.

*Exclusion criteria* is the environmental distance from presence points (environmental filters, according to Varela et al 2014).

*Number of PA points* is different for each algorithm:
- Bioclim: no PAs
- Maxent and GLM: 10000 random PA points .
- Random Forest and SVM: PAs = n presence. 

### Data partition

- 10-fold cross-validation for the species with > 50 records
- Bootstrap (10% of points for training), with 10 repetitions, for the species with <=50 records

## Results

It was not possible to run the BRT algorithm for some species due to the number of records. These species are:

- Amazona brasiliensis
- Automolus lammi
- Conopophaga cearae
- Cotinga maculata
- Glaucis dohrnii
- Leptodon forbesi
- Onychorhynchus swainsoni
- Phylloscartes beckeri
- Pyriglena atra
