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
data <- read.csv("/media/lorenzo/External HDD/00_SUSCEPTIBILITY/02_data/data2.csv")
#head(data)
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

if(file.exists("aux.csv")){
  res = read.csv("aux.csv")
}else{
  res = matrix(NA, ncol = 31, nrow = nrow(data))
}
issues = c()
for(i in which(is.na(res[,1]) )){# & !(data$day %in% c(1,2,31)) 
  tryCatch({
    err = FALSE
    day = data$day[i]; month = data$month[i]; year = data$year[i]
    current = c()
    for(j in 1:length(variable_verticals)){
      var = variable_verticals[[j]][[1]]
      nc_var = variable_verticals[[j]][[2]]
      verticals =  variable_verticals[[j]][[3]]
      #vertical = verticals[1] 
      for(vertical in verticals){
        filename= paste(path_CMCC_files, generate_name(var,vertical,month,year), sep ="")
        nc_data <- nc_open(filename)
        lon = data$lon[i]
        lat = data$lat[i]
        lons <- as.matrix(ncvar_get(nc_data, "lon"))
        lats <- as.matrix(ncvar_get(nc_data, "lat"))
        id_lon = arrayInd(which.min(abs(lons-lon)), dim(lons))[1]
        id_lat = arrayInd(which.min(abs(lats-lat)), dim(lons))[2]
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
                                start = c(id_lon,id_lat,1,day_indices[1]), 
                                count =c(1,1,1,length(day_indices)) )
          }else{
            values <- ncvar_get(nc_data, nc_var, 
                                start = c(id_lon,id_lat,day_indices[1]), 
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
                                      start = c(id_lon,id_lat,1), 
                                      count =c(1,1,length(time)))
    nc_close(nc_data)
    var_snow = "lwe_thickness_of_surface_snow_amount"; nc_var_snow = "W_SNOW"; vertical_snow = "0.004999999888241291";
    filename_snow = paste(path_CMCC_files, generate_name(var_snow,vertical_snow,month,year), sep ="")
    nc_data = nc_open(filename_snow)
    values_snow <- ncvar_get(nc_data, nc_var_snow, 
                             start = c(id_lon,id_lat,1), 
                             count = c(1,1,length(time)))
    nc_close(nc_data)
    if(day<3){
      previous_month = compute_previous_month(month,year)$month;
      previous_year = compute_previous_month(month,year)$year;
      filename_previous_precipitation = paste(path_CMCC_files, generate_name(var_precipitation,vertical_precipitation,previous_month,previous_year), sep ="")
      nc_data = nc_open(filename_previous_precipitation) 
      previous_time <- ncvar_get(nc_data, "time")
      values_previous_precipitation <- ncvar_get(nc_data, nc_var_precipitation, 
                                                 start = c(id_lon,id_lat,1), 
                                                 count =c(1,1,length(previous_time)))
      nc_close(nc_data)
      values_precipitation = c(values_previous_precipitation,values_precipitation); 
      rm(values_previous_precipitation);
      filename_previous_snow = paste(path_CMCC_files, generate_name(var_snow,vertical_snow,previous_month,previous_year), sep ="")
      nc_data = nc_open(filename_previous_snow) 
      values_previous_snow <- ncvar_get(nc_data, nc_var_snow, 
                                        start = c(id_lon,id_lat,1), 
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
      write.csv(res, "aux.csv", row.names = FALSE)
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
col_names = c("id_count", col_names)
head(data)
res = as.data.frame(res)
names(res) = col_names
new_data = cbind(data, res)
head(new_data)
#table(data$day[which(is.na(new_data$id_count))])
write.csv(new_data, "data_with_cmcc", row.names = FALSE)
for(col_name in col_names){
  print(paste(col_name, "percentage NA =" ,sum(is.na(new_data[,col_name]))/nrow(new_data)*100, "%"))
  hist(new_data[,col_name], main = col_name)
}
