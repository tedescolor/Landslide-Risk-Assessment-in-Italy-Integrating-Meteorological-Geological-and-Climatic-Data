###############################################################################
############## DATI ATIMOSFERICI
###############################################################################
{
  # Package names
  packages <-
    c("doParallel","foreach","fields", "sf", "geosphere", "dplyr", "ncdf4", "lubridate", "raster", "zoo")
  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages],repos='http://cran.us.r-project.org')
  }
  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))
}

compute_previous_month <- function(month, year) {
  # Check if the provided month is valid
  if(month < 1 || month > 12) {
    stop("Invalid month. Please provide a month between 1 and 12.")
  }
  
  # Calculate the previous month and adjust the year if needed
  if(month == 1) {
    prev_month <- 12
    prev_year <- year - 1
  } else {
    prev_month <- month - 1
    prev_year <- year
  }
  
  # Return the previous month and year as a list
  return(list(month = prev_month, year = prev_year))
}


generate_name = function(var, vertical, month,year){
  sprintf("era5downscaled_%s_vertical_%s_%d_%d.nc", var, vertical, year, month)
}

path_CMCC_files = "/media/lorenzo/External HDD/CMCC/"
# Load your data frame
data <- read.csv("/media/lorenzo/External HDD/00_SUSCEPTIBILITY/02_data/data_with_cmcc_new.csv")
head(data)
now_string <- function() {
  format(Sys.time(), "%Y%m%d_%H%M%S")
}

variable_verticals <- list(
  list("air_temperature","T_2M",  "0.004999999888241291"),
  list("precipitation_amount", "TOT_PREC",  "0.004999999888241291"),
  list("lwe_thickness_of_surface_snow_amount","W_SNOW",  "0.004999999888241291"),
  list("lwe_thickness_of_moisture_content_of_soil_layer", "W_SO", c("0.004999999888241291",
                                                                    "0.019999999552965164",
                                                                    "0.05999999865889549",
                                                                    "0.18000000715255737",
                                                                    "0.5400000214576721",
                                                                    "1.6200000047683716",
                                                                    "4.860000133514404",
                                                                    "14.579999923706055"))
)
operations = list(list("max", max),list("mean", mean))
intervals <- c(6, 12, 24, 48)



# Define function to generate random point
generate_random_point <- function(data) {
  # Get the range of existing latitudes and longitudes
  lat_range <- range(data$lat)
  lon_range <- range(data$lon)
  
  # Generate random latitude and longitude within the bounds
  lat_random <- runif(1, min = lat_range[1], max = lat_range[2])
  lon_random <- runif(1, min = lon_range[1], max = lon_range[2])
  
  return(list(lon = lon_random, lat = lat_random))
}

# Define a function to calculate minimum distance
find_valid_point <- function(data) {
  repeat {
    # Generate a random point
    random_point <- generate_random_point(data)
    
    # Calculate Haversine distances from the random point to all points in 'data'
    distances <- distHaversine(matrix(c(data$lon, data$lat), ncol = 2), c(random_point$lon,random_point$lat))
    
    # Check if the minimum distance is less than 50 km (50000 meters)
    if (min(distances) < 50000) {
      return(random_point)
    }
  }
}
# Define the function to generate random day, month, and year
generate_random_date <- function() {
  # Define the date range (from 1/1/2000 to 31/12/2020)
  start_date <- as.Date("2000-01-01")
  end_date <- as.Date("2021-12-31")
  
  # Generate a random date within the range
  random_date <- sample(seq(start_date, end_date, by = "day"), 1)
  
  # Extract day, month, and year from the random date
  day <- as.integer(format(random_date, "%d"))
  month <- as.integer(format(random_date, "%m"))
  year <- as.integer(format(random_date, "%Y"))
  
  # Return day, month, and year
  return(list(day = day, month = month, year = year))
}

# Generate a valid random point



if(file.exists("aux_zeros.csv")){
  res = read.csv("aux_zeros.csv")
}else{
  res = matrix(NA, ncol = 31+5, nrow = 10000)
}
issues = c()
for(i in which(is.na(res[,1]) )){# & !(data$day %in% c(1,2,31)) 
  tryCatch({
    err = FALSE
    random_point <- find_valid_point(data)
    lon = random_point$lon
    lat = random_point$lat
    random_date <- generate_random_date()
    day = random_date$day; month = random_date$month; year = random_date$year
    current = c(lon,lat,day,month,year)
    for(j in 1:length(variable_verticals)){
      var = variable_verticals[[j]][[1]]
      nc_var = variable_verticals[[j]][[2]]
      verticals =  variable_verticals[[j]][[3]]
      irow_final = NA; icol_final = NA;
      #vertical = verticals[1] 
      for(vertical in verticals){
        filename= paste(path_CMCC_files, generate_name(var,vertical,month,year), sep ="")
        nc_data <- nc_open(filename)

        lons <- as.matrix(ncvar_get(nc_data, "lon"))
        lats <- as.matrix(ncvar_get(nc_data, "lat"))
        #as the CMCC has lat and lon coordinates that not not respect the roundeness of the planet, we have first to obtain a map that associate to each 
        # (lat, lon) an (indice_x, indice_y) so that, when we take a point p = (plat, plon), we check which point is the nearest and use the relative (indice_x, indice_y)
        #SLOW VERSION
        # irow_final = NA
        # icol_final = NA
        # current_dist = Inf
        # for(irow in 1:nrow(lons)){
        #   for(icol in 1:ncol(lons)){
        #     new_dist = distm(c(lons[irow,icol], lats[irow,icol]), c(lon, lat), fun = distHaversine)
        #     if(current_dist>new_dist){
        #       current_dist = new_dist
        #       irow_final = irow
        #       icol_final = icol
        #     }
        #   }
        # }
        #FAST VERSION
        if(is.na(irow_final)){
          indices = arrayInd(which.min(distm(cbind(c(lons), c(lats)), c(lon, lat), fun = distHaversine)), dim(lons))
          irow_final = indices[1]; icol_final = indices[2];
        }

        time <- ncvar_get(nc_data, "time")
        
        # Get the time unit (assuming it's in the format "seconds since 1980-01-01")
        start_date <- as.POSIXct("1980-01-01", tz = "UTC")
        
        # Convert the time to POSIXct format
        time_converted <- start_date + seconds(time)
        
        # Convert the target date to a Date object
        target_date <- as.Date(sprintf("%04d-%02d-%02d", year, month, day))
        
        # Filter data for the specific day
        day_start <- as.POSIXct(target_date, tz = "UTC")
        day_end <- day_start + days(1) - seconds(1)
        
        day_indices <- which(time_converted >= day_start & time_converted <= day_end)
        if(length(day_indices)>0){
          if(var == "lwe_thickness_of_moisture_content_of_soil_layer"){
            values <- ncvar_get(nc_data, nc_var, 
                                start = c(irow_final,icol_final,1,day_indices[1]), 
                                count =c(1,1,1,length(day_indices)) )
          }else{
            values <- ncvar_get(nc_data, nc_var, 
                                start = c(irow_final,icol_final,day_indices[1]), 
                                count =c(1,1,length(day_indices)) )
          }
          for(k in 1:length(operations)){
            current = c(current, operations[[k]][[2]](values))
          }
        }else{
          err = TRUE
          current = c(current, rep(NA, length(operations)))
        }
        nc_close(nc_data)
      }
    }
    ## construct AL
    var_precipitation = "precipitation_amount"; nc_var_precipitation = "TOT_PREC"; vertical_precipitation = "0.004999999888241291"
    filename_precipitation = paste(path_CMCC_files, generate_name(var_precipitation,vertical_precipitation,month,year), sep ="")
    nc_data = nc_open(filename_precipitation) 
    time <- ncvar_get(nc_data, "time")
    values_precipitation <- ncvar_get(nc_data, nc_var_precipitation, 
                                      start = c(irow_final,icol_final,1), 
                                      count =c(1,1,length(time)))
    nc_close(nc_data)
    var_snow = "lwe_thickness_of_surface_snow_amount"; nc_var_snow = "W_SNOW"; vertical_snow = "0.004999999888241291";
    filename_snow = paste(path_CMCC_files, generate_name(var_snow,vertical_snow,month,year), sep ="")
    nc_data = nc_open(filename_snow)
    values_snow <- ncvar_get(nc_data, nc_var_snow, 
                             start = c(irow_final,icol_final,1), 
                             count = c(1,1,length(time)))
    nc_close(nc_data)
    if(day<3){
      previous_month = compute_previous_month(month,year)$month;
      previous_year = compute_previous_month(month,year)$year;
      filename_previous_precipitation = paste(path_CMCC_files, generate_name(var_precipitation,vertical_precipitation,previous_month,previous_year), sep ="")
      nc_data = nc_open(filename_previous_precipitation) 
      previous_time <- ncvar_get(nc_data, "time")
      values_previous_precipitation <- ncvar_get(nc_data, nc_var_precipitation, 
                                                 start = c(irow_final,icol_final,1), 
                                                 count =c(1,1,length(previous_time)))
      nc_close(nc_data)
      values_precipitation = c(values_previous_precipitation,values_precipitation); 
      rm(values_previous_precipitation);
      filename_previous_snow = paste(path_CMCC_files, generate_name(var_snow,vertical_snow,previous_month,previous_year), sep ="")
      nc_data = nc_open(filename_previous_snow) 
      values_previous_snow <- ncvar_get(nc_data, nc_var_snow, 
                                        start = c(irow_final,icol_final,1), 
                                        count =c(1,1,length(previous_time)))
      nc_close(nc_data)
      values_snow = c(values_previous_snow,values_snow); 
      rm(values_previous_snow);
      time = c(previous_time, time)
      rm(previous_time)
    }
    
    time = time[2:length(time)]
    # Convert the time to POSIXct format
    time_converted <- start_date + seconds(time)
    day_indices <- which(time_converted >= day_start & time_converted <= day_end)
    values_al = values_precipitation[2:length(values_precipitation)] + 
      (values_snow[2:length(values_precipitation)]-
         values_snow[1:(length(values_precipitation)-1)])
    values_al = zoo(values_al, time_converted)
    for(inter in intervals){
      cumsum_inter <- rollapply(values_al, width = inter, FUN = sum, fill = NA,align = "right")
      if(length(day_indices)>0){
        values = cumsum_inter[day_indices]
        for(k in 1:length(operations)){
          current = c(current, operations[[k]][[2]](values))
        }
      }else{
        err = TRUE
        current =  c(current,rep(NA, length(operations)))
      }
    }
    if(err){
      print(paste(i, "something missing."))
      issues = c(issues, i)
    }else{
      print(paste(i, "done."))
      res[i,] = c(i,current)
      write.csv(res, "aux_zeros.csv", row.names = FALSE)
    }
  }, error = function(cond){
    tryCatch({nc_close(nc_data)}, error = function(cond){})
    print(paste(i, "ERROR."))
  })
  
}
col_names <- c()
variable_verticals_nms <- list(
  list("temperature", ""),
  list("precipitation",  ""),
  list("snow",""),
  list("soil_moisture", 1:8)
)

for(j in 1:length(variable_verticals_nms)){
  var = variable_verticals_nms[[j]][[1]]
  verticals =  variable_verticals_nms[[j]][[2]]
  for(vertical in verticals){
    for(k in 1:length(operations)){
      col_names = c(col_names, paste(var,toString(vertical),"_", operations[[k]][[1]], sep = ""))
    }
  }
}
for(inter in intervals){
  for(k in 1:length(operations)){
    col_names = c(col_names, paste("liquid_cumsum_h", inter,"_", operations[[k]][[1]],sep = ""))
  }
}
col_names = c("id_count",   "lon","lat","day","month","year",col_names)
#head(data)
res = as.data.frame(res)
names(res) = col_names
#names(data)

res = res[!is.na(res$id_count),]
names(res)
nrow(res)
names(data)

### add all the other variables:


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
df_italica = res#read.csv("./02_data/01_ITALIC/ITALICA-v2.csv", sep = ";")
sf_slope_units = read_sf("./02_data/02_SU/su_italia.gpkg")
sf_litology = read_sf("./02_data/06_LITOLOGY/litology_italy.gpkg")
climate_zones = read.csv("./02_data/05_ZONE_CLIMATICHE/climate_zone.csv")
##### prepare df_italica
nrow(df_italica)
# df_italica$utc_date = as.POSIXct(df_italica$utc_date, format = "%d/%m/%Y %H:%M", tz = "UTC")
# hist(df_italica$utc_date,"years", freq = TRUE)
# filter only date after 01-01-2000
#df_italica = df_italica[sapply(df_italica$utc_date, function(d) as.numeric(format(d, "%Y"))>=2000),]
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
data$true <-NULL
df_italica_final$event = 0
data$event = 1
names(df_italica_final)[names(df_italica_final) == 'id_count'] <- 'id'
for(nm in names(data)){
  if(!(nm%in%names(df_italica_final))){
    print(nm)
    df_italica_final[,nm] = NA
  }

}
df_italica_final = df_italica_final[,names(data)]

merged_data = rbind(data,df_italica_final)
write.csv(merged_data, "./02_data/merged_data01.csv", row.names = FALSE)
names(merged_data)


# new_data = cbind(data, res)
# head(new_data)
# #table(data$day[which(is.na(new_data$id_count))])
# write.csv(new_data, "data_with_cmcc_new", row.names = FALSE)
# for(col_name in col_names){
#   print(paste(col_name, "percentage NA =" ,sum(is.na(new_data[,col_name]))/nrow(new_data)*100, "%"))
#   hist(new_data[,col_name], main = col_name)
# }
