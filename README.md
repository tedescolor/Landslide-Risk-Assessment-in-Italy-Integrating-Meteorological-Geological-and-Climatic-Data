# Landslide Risk Assessment in Italy: Integrating Meteorological, Geological, and Climatic Data

## Overview
This project aims to develop a model to assess landslide risk across Italian slope units by integrating diverse data sources, including meteorological variables, soil moisture, and lithotype clusters. By building a comprehensive dataset, we intend to evaluate the susceptibility of each slope unit to landslides, supporting risk mitigation strategies and informed land-use planning.

## Key Objectives
1. **Landslide Data**: We utilize the [ITAlian rainfall-induced LandslIdes CAtalogue (ITALIC)](https://zenodo.org/records/8009366), a comprehensive record of rainfall-induced landslides, to serve as the foundation for our dataset.
2. **Slope Units**: Slope units are mapped using a dataset from [IRPI CNR](https://geomorphology.irpi.cnr.it/tools/slope-units), which provides natural geomorphological divisions, ensuring a topographically consistent analysis of landslide susceptibility.
3. **Meteorological Variables**: Hourly data for temperature, liquid precipitation, solid precipitation, and snowmelt are sourced from the [CMCC VHR-REA_IT dataset](https://www.mdpi.com/2306-5729/6/8/88). These variables include:
   - Temperature at 2 meters (T_2M)
   - Total precipitation (TOT_PREC)
   - Snow amount (W_SNOW)
   - Soil moisture content at various depths (W_m_SO), where *m* represents depths of 0.01, 0.03, 0.09, 0.27, 0.81, 2.43, and 7.29 meters from the surface

   Derived variables such as Liquid Cumulative Sum (LCS) track liquid water input from precipitation and snowmelt over different intervals, aiding in understanding landslide triggers.
4. **Soil Moisture**: Soil water content variables are recorded for multiple depths to evaluate water accumulation effects in slope stability.
5. **Climate Zones**: Climate zones are defined based on [Table A of D.P.R. 412/93](https://www.certifico.com/impianti/documenti-impianti/337-documenti-impianti-riservati/7099-zone-climatiche-tabella-a-aggiornata-d-p-r-412-1993) updated as of 2009. Each point is assigned a climate zone determined by the nearest municipality, based on data from the [Italy Geo file](https://github.com/MatteoHenryChinaski/Comuni-Italiani-2018-Sql-Json-excel/blob/master/italy_geo.xlsx).
6. **Terrain Analysis**: Terrain classification and lithotype clustering are based on studies such as ["Parameter-free delineation of slope units and terrain subdivision of Italy"](https://www.sciencedirect.com/science/article/pii/S0169555X20300969), providing an accurate subdivision of Italy's complex terrain for hazard modeling.

## Directory Structure
The data folder is organized as follows:
```
├── CLIMATE_ZONES               # Climate zone files and scripts for plotting
│   ├── 99_archive              # Archive of older climate zone data
│   ├── climate_zone.csv        # Current climate zone data
│   ├── elenco_zone_climatiche_cleaned.xlsx # Cleaned list of climate zones
│   └── plot_climate_zone.R     # R script for plotting climate zones
├── CMCC                        # Scripts and README for handling CMCC data
│   ├── README.md
│   ├── script_check_files.py   # Python script to check data integrity
│   ├── script_delete_corrupted.py  # Python script to delete corrupted data
│   └── script.py               # General Python script for data processing
├── ITALIC                      # ITALIC database files
│   └── README.md
├── LITOLOGY                    # Data on lithology
│   └── README.md
├── SLOPE_UNITS                 # Data and README for slope units
│   └── README.txt
├── add_cmcc_to_data.R          # R script to add CMCC data to the dataset
├── add_zeros_to_data.R         # R script to add zeros to the dataset
├── data.csv                    # Initial raw data file
├── data_with_cmcc.csv          # Data with added CMCC information
├── data_with_cmcc_with_zeros.csv # Final dataset with zeros added
└── prepare_data.R              # R script to prepare the initial data

```
- **CLIMATE_ZONES**: Contains climate zone data and related scripts.
- **CMCC**: Contains the scripts for data downloading and cleaning.
- **ITALIC**: Contains landslide data sourced from ITALIC.
- **LITOLOGY** and **SLOPE_UNITS**: Store lithotype and slope unit data, respectively.

## Workflow
0. **download data**: Download the data from each of the folders—CMCC, ITALIC, LITHOLOGY, and SLOPE_UNITS—by following the instructions provided in the respective README files.  
1. **prepare_data.R**: Prepares the initial dataset without CMCC data.
2. **add_cmcc_to_data.R**: Adds the CMCC meteorological data.
3. **add_zeros_to_data.R**: Adds zero values where needed to balance the dataset.


## Methodology
The model integrates atmospheric, geological, and climatic data to create a comprehensive dataset for evaluating landslide susceptibility across Italy. The data processing pipeline includes preparing the base data, merging it with CMCC data, and further preprocessing to balance landslide and non-landslide events for effective model training.

Further details of the methodology are available in the documentation.

## Usage
This project is designed to support researchers, environmental agencies, and policymakers in understanding and mitigating landslide risks in Italy. The dataset is prepared for machine learning applications, making it suitable for developing susceptibility models and early warning systems.

## References
- **ITAlian rainfall-induced LandslIdes CAtalogue (ITALIC)**: [Link](https://zenodo.org/records/8009366)
- **Slope Units Dataset**: [Link](https://geomorphology.irpi.cnr.it/tools/slope-units)
- **CMCC VHR-REA_IT dataset**: [Link](https://www.mdpi.com/2306-5729/6/8/88)
- **Terrain Analysis**: [link](https://www.sciencedirect.com/science/article/pii/S0169555X20300969)

## Contact
For questions or collaboration opportunities, please contact:
**Lorenzo Tedesco**, Department of Economic Sciences, University of Bergamo, Via dei Caniana 2, 24127 BG, Bergamo, Italy.
Email: Lorenzo.tedesco@unibg.it


