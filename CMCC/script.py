import ddsapi
import os
from concurrent.futures import ThreadPoolExecutor
import itertools

def download_data(params):
    year, month, var_vertical = params
    var, vertical = var_vertical
    # Include vertical in the filename
    filename = f"era5downscaled_{var}_vertical_{vertical}_{year}_{month}.nc"
    
    # Check if the file already exists
    if not os.path.exists(filename):
        client = ddsapi.Client()  # It might be beneficial to create a new client instance per thread if needed
        client.retrieve(
            "era5-downscaled-over-italy",
            "hourly",
            {
                "vertical": [vertical],
                "time": {
                    "hour": [f"{hour:02}" for hour in range(24)],
                    "year": [year],
                    "month": [month],
                    "day": [str(day) for day in range(1, 31)]  # Adjust for different month lengths if necessary
                },
                "variable": [var],
                "format": "netcdf",
            },
            filename
        )
    else:
        print(f"File {filename} already exists, skipping download.")

years = [str(year) for year in range(2000, 2023)]
months = [str(month) for month in range(1, 13)]
variable_verticals = [
    (var, 0.004999999888241291) for var in (
        "air_temperature",
        "lwe_thickness_of_surface_snow_amount",
        "precipitation_amount",
    )
] + [
    ("lwe_thickness_of_moisture_content_of_soil_layer", h) for h in [
        0.004999999888241291,
        0.019999999552965164,
        0.05999999865889549,
        0.18000000715255737,
        0.5400000214576721,
        1.6200000047683716,
        4.860000133514404,
        14.579999923706055,
    ]
]

# Use ThreadPoolExecutor to parallelize downloads
with ThreadPoolExecutor(max_workers=20) as executor:
    # Create a list of all combinations of years, months, and variable_verticals
    all_params = list(itertools.product(years, months, variable_verticals))
    # Map download_data function across all parameter combinations
    results = executor.map(download_data, all_params)

