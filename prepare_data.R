{
  # Package names
  packages <-
    c("doParallel","foreach","fields", "sf", "geosphere", "dplyr", "ncdf4")
  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages],repos='http://cran.us.r-project.org')
  }
  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))
}
compute_time = function(text){
  start = Sys.time()
  eval(parse(text = text))
  print(Sys.time()-start)
}

now_string <- function() {
  format(Sys.time(), "%Y%m%d_%H%M%S")
}

find_climate_zone_for_point = function(climate_zones,longitude,latitude){
  climate_zones$zone[which.min(apply(climate_zones[,c(1,2)], 1, 
                                     function(p)distHaversine(p,c(longitude,latitude)) ))]
}

path = "/media/lorenzo/External HDD/00_SUSCEPTIBILITY"
setwd(path)
df_italica = read.csv("./02_data/01_ITALIC/ITALICA-v2.csv", sep = ";")
sf_slope_units = read_sf("./02_data/02_SU/su_italia.gpkg")
sf_litology = read_sf("./02_data/06_LITOLOGY/litology_italy.gpkg")
climate_zones = read.csv("./02_data/05_ZONE_CLIMATICHE/climate_zone.csv")
##### prepare df_italica
nrow(df_italica)
df_italica$utc_date = as.POSIXct(df_italica$utc_date, format = "%d/%m/%Y %H:%M", tz = "UTC")
hist(df_italica$utc_date,"years", freq = TRUE)
# filter only date after 01-01-2000
df_italica = df_italica[sapply(df_italica$utc_date, function(d) as.numeric(format(d, "%Y"))>=2000),]
nrow(df_italica)
head(df_italica)


###############################################################################
############## SLOPE UNITS
###############################################################################
#Convert df_italica to an sf object, assuming WGS84 as initial CRS
df_italica_sf <- st_as_sf(df_italica, coords = c("lon", "lat"), crs = 4326)

# Check the CRS of both sf objects
print(st_crs(df_italica_sf))
print(st_crs(sf_slope_units))

# If the CRS differs, transform df_italica_sf to match sf_slope_units
df_italica_sf_transformed <- st_transform(df_italica_sf, st_crs(sf_slope_units))

# Perform the spatial join
df_italica_joined <- st_join(df_italica_sf_transformed, sf_slope_units, join = st_within)

# Convert back to a regular dataframe (if desired) and clean up
df_italica_final <- as.data.frame(df_italica_joined)
df_italica_final$geometry <- NULL  # Remove geometry column
df_italica_final$lon = df_italica$lon
df_italica_final$lat = df_italica$lat
sum(is.na(df_italica_final$cat))/nrow(df_italica_final)
table(df_italica_final$cat) %>% 
  as.data.frame() %>% 
  arrange(desc(Freq))


###############################################################################
############## CLIMATE ZONES
###############################################################################
head(climate_zones)
zones = array(NA, dim = nrow(df_italica_final))
#setup parallel backend to use many processors
# pb = txtProgressBar(min = 0, max =nrow(df_italica_final), initial = 0) 
# for(i in 1:nrow(df_italica_final)){
#   setTxtProgressBar(pb,i)
#   zones[i] = find_climate_zone_for_point(climate_zones,df_italica_final$lon[i],df_italica_final$lat[i])
# }
# df_italica_final$climate_zone = zones

numCores <- detectCores() - 1
cl <- makeCluster(numCores)
registerDoParallel(cl)

# Assuming df_italica_final and climate_zones are already defined
# Parallelize the for loop
zones <- foreach(i = 1:nrow(df_italica_final), .combine = c, .packages = packages) %dopar% {
  find_climate_zone_for_point(climate_zones, df_italica_final$lon[i], df_italica_final$lat[i])
}
# Stop the cluster
stopCluster(cl)
# Assign the result to the data frame
df_italica_final$climate_zone <- zones



###############################################################################
############## LITOLOGY
###############################################################################

df_italica_final_sf <- st_as_sf(df_italica_final, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
invalid_geometries <- !st_is_valid(sf_litology)
if(any(invalid_geometries)) {
  sf_litology$geom[invalid_geometries] <- st_make_valid(sf_litology$geom[invalid_geometries])
}


# Perform the spatial join with sf_new
df_italica_joined <- st_join(df_italica_final_sf, sf_litology, join = st_within)
# Convert back to a regular dataframe and remove the geometry column
df_italica_final <- as.data.frame(df_italica_joined)
df_italica_final$geometry <- NULL  # Remove geometry column
head(df_italica_final)
     


###############################################################################
############## SAVE OUTPUT
###############################################################################
# Count rows with NA (due to missing slope units) and remove that rows
sum(complete.cases(df_italica_final))/nrow(df_italica_final)
df_italica_final = df_italica_final[complete.cases(df_italica_final), ]
write.csv(df_italica_final, "./02_data/data.csv", row.names = FALSE)
names(df_italica_final)

