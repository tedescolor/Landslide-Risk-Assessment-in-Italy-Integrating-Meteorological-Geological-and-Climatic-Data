{
  # Package names
  packages <-
    c("ggplot2", "sf", "rnaturalearth","rnaturalearthdata", "dplyr")
  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages],repos='http://cran.us.r-project.org')
  }
  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))
} #LOAD PACKAGES


# Read the dataset
data <- read.csv("/media/lorenzo/External HDD/00_SUSCEPTIBILITY/02_data/05_ZONE_CLIMATICHE/climate_zone.csv")

# Ensure the sf object is loaded correctly
italy <- ne_countries(scale = "medium", returnclass = "sf") %>% 
  dplyr::filter(admin == "Italy")

# Define color mapping for climate zones
zone_colors <- c("A" = "red", "B" = "blue", "C" = "green", "D" = "purple", "E" = "orange", "F" = "brown")

# Plot the data
ggplot() +
  geom_sf(data = italy, fill = "white", color = "black") +
  geom_point(data = data, aes(x = longitude, y = latitude, color = zone), size = .5) +
  scale_color_manual(values = zone_colors) +
  labs(title = "Climate Zones in Italy", x = "Longitude", y = "Latitude", color = "Climate Zone") +
  theme_minimal()
