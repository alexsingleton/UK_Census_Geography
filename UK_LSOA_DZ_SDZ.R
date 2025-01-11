library(tidyverse)
library(sf)
library(magrittr)
library(readxl)

#=============================================
# LSOA, Data Zones, Super Data Zones Geometry
#=============================================

# England and Wales
#------------------
LSOA_21_BFC <- st_read("https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Lower_layer_Super_Output_Areas_December_2021_Boundaries_EW_BFC_V10/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson")
# Clean and make OSGB
LSOA_21_BFC %<>%
  select(LSOA21CD) %>%
  rename(geography_code = LSOA21CD) %>%
  st_transform(my_data, crs = 27700)


# Scotland
#------------------
temp_zip <- tempfile(fileext = ".zip")
# Download the ZIP
download.file(
  url = "https://maps.gov.scot/ATOM/shapefiles/SG_DataZoneBdry_2022.zip",
  destfile = temp_zip,
  mode = "wb"
)
# Unzip into a temporary directory
unzip_dir <- tempdir()
unzip(temp_zip, exdir = unzip_dir)
# Read the shapefile as an sf object
DZ_22 <- st_read(file.path(unzip_dir, "SG_DataZoneBdry_2022_MHW.shp"))
# Clean and make OSGB
DZ_22 %<>%
  select(DZCode) %>%
  rename(geography_code = DZCode) %>%
  st_transform(my_data, crs = 27700)

# Northern Ireland
#------------------
temp_zip <- tempfile(fileext = ".zip")
# Download the ZIP
download.file(
  url = "https://www.nisra.gov.uk/sites/nisra.gov.uk/files/publications/geography-sdz2021-geojson.zip",
  destfile = temp_zip,
  mode = "wb"
)
# Unzip into a temporary directory
unzip_dir <- tempdir()
unzip(temp_zip, exdir = unzip_dir)
# Read the shapefile as an sf object
SDZ_21 <- st_read(file.path(unzip_dir, "SDZ2021.geojson"))
# Clean and make OSGB
SDZ_21 %<>%
  select(SDZ2021_cd) %>%
  rename(geography_code = SDZ2021_cd) %>%
  st_transform(my_data, crs = 27700)

UK_LSOA_DZ_SDZ <- LSOA_21_BFC %>%
  bind_rows(DZ_22) %>%
  bind_rows(SDZ_21)


# Chunk size
chunk_size <- 5000

# Create a grouping index based on chunk_size
num_rows   <- nrow(UK_LSOA_DZ_SDZ)
group_idx  <- ceiling(seq_len(num_rows) / chunk_size)

# Split the sf_data into a list of smaller sf objects
sf_chunks  <- split(UK_LSOA_DZ_SDZ, group_idx)

# Write each chunk to a separate GeoPackage file
for (i in seq_along(sf_chunks)) {
  file_name <- paste0("./data/LSOA_DZ_SDZ/chunk_", i, "UK_LSOA_DZ_SDZ.gpkg")  # file name for each chunk
  st_write(sf_chunks[[i]], dsn = file_name)  # writes a separate GeoPackage
}



##################################################
# Reading Example
##################################################

# Reading function
# Usage example:
# combined_sf <- combine_chunk_gpkgs("path/to/gpkgs")

combine_chunk_gpkgs <- function(gpkg_path) {
  gpkg_files <- list.files(
    path       = gpkg_path, 
    pattern    = "^chunk.*\\.gpkg$",  # Regex for filenames starting with "chunk" and ending with .gpkg
    full.names = TRUE
  )
  
  # Read each file into a list of sf objects
  sf_list <- lapply(gpkg_files, st_read)
  
  # Combine all sf objects into a single sf object
  combined_sf <- do.call(rbind, sf_list)
  
  # Return the combined sf
  return(combined_sf)
}

UK_LSOA_DZ_SDZ <- combine_chunk_gpkgs("./data/LSOA_DZ_SDZ/")

#==================================================
# OA lookup to - LSOA, Data Zones, Super Data Zones 
#==================================================

# England and Wales
#------------------

EW <- st_read("https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/OA_LSOA_MSOA_EW_DEC_2021_LU_v3/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson")

EW %>%
  st_drop_geometry() %>%
  rename(OA = OA21CD,
         geography_code = LSOA21CD) %>%
  select(OA,geography_code) %>%
  as_tibble()


# Scotland
#------------------

# Define the WFS URL
wfs_url <- "https://maps.gov.scot/server/services/NRS/Census2022/MapServer/WFSServer?request=GetCapabilities&service=WFS"

# Query the WFS service
S <- st_read(wfs_url, layer = "CEN2022:OutputAreaCent2022")
# Clean Up
S %<>%
  rename(OA = code) %>%
  select(OA)

# Point in Polygon
S_lookup <- st_join(
  S, 
  DZ_22, 
  join      = st_intersects,  
  left      = TRUE        
)%>%
  st_drop_geometry() 




# Northern Ireland
#------------------


url <- "https://www.nisra.gov.uk/system/files/statistics/geography-census-2021-population-weighted-centroids-for-data-zones-and-super-data-zones.xlsx"

# Create a temporary file
temp_file <- tempfile(fileext = ".xlsx")

# Download the file
download.file(url, destfile = temp_file, mode = "wb")

# Read DZ Centroids downloaded file
N <- read_excel(temp_file, sheet = "DZ2021")

# Create SF
N <- st_as_sf(
  N,
  coords = c("X", "Y"),      # coordinate columns
  crs    = 29903             # Irish Grid (TM75) - verify with NISRA if correct
) %>%
  st_transform(my_data, crs = 27700)

N %<>%
  rename(OA = DZ2021_code) %>%
  select(OA)

# Point in Polygon
N_lookup <- st_join(
  N, 
  SDZ_21, 
  join      = st_intersects,  
  left      = TRUE        
) %>%
  st_drop_geometry() 


# Write Lookups
#------------------
write_csv(EW,"./data/lookup/LSOA_DZ_SDZ/EW.csv")
write_csv(N_lookup,"./data/lookup/LSOA_DZ_SDZ/N.csv")
write_csv(S_lookup,"./data/lookup/LSOA_DZ_SDZ/S.csv")

UK <- EW %>%
  bind_rows(N_lookup) %>%
  bind_rows(S_lookup)

write_csv(UK,"./data/lookup/LSOA_DZ_SDZ/UK.csv")

