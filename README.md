# UK LSOA, Data Zones, and Super Data Zones Geometries

This repository contains code to download, process, and combine **Lower Layer Super Output Areas (LSOAs)** for England and Wales, **Data Zones (DZs)** for Scotland, and **Super Data Zones (SDZs)** for Northern Ireland into a single UK-wide dataset. It also demonstrates how to join **Output Areas (OAs)** to these geographies and store lookup tables for reference.

---

## Overview

This code automates the process of:
- **Downloading** boundary data for:  
  - LSOAs in England and Wales  
  - Data Zones in Scotland  
  - Super Data Zones in Northern Ireland
- **Transforming** the coordinate systems to the Ordnance Survey National Grid (EPSG:27700)
- **Chunking** large datasets into smaller GeoPackage files (for easier handling and storage)
- **Merging** these smaller chunks back into a single dataset when needed
- **Joining** Output Area (OA) data for each region to the respective geographies
- **Creating** and saving CSV lookup tables

---

## Prerequisites

You will need the following packages installed in R:

```r
install.packages(c("tidyverse", "sf", "magrittr", "readxl"))
```

Additionally, ensure you have internet access for downloading the shapefiles and geojson files, and that you have write permissions to create directories and files as described in this README.

---

## Workflow Summary

1. **Download** boundary data for each region (England & Wales, Scotland, Northern Ireland).  
2. **Clean** and **transform** them to EPSG:27700 (OSGB).  
3. **Combine** them into one dataset (`UK_LSOA_DZ_SDZ`).  
4. **Chunk** the combined dataset into multiple smaller `.gpkg` files.  
5. **Read** these chunks into a single sf object when needed (using a helper function).  
6. **Download** Output Area data for each region, then join them to the respective boundaries.  
7. **Write** out the final lookup tables as CSV files.

## Directory Structure

Below is an example directory layout after running the script:

```
.
├── data
│   ├── LSOA_DZ_SDZ
│   │   ├── chunk_1UK_LSOA_DZ_SDZ.gpkg
│   │   ├── chunk_2UK_LSOA_DZ_SDZ.gpkg
│   │   └── ... (additional chunk files)
│   └── lookup
│       └── LSOA_DZ_SDZ
│           ├── EW.csv
│           ├── N.csv
│           ├── S.csv
│           └── UK.csv
├── script.R
└── README.md
```

---
