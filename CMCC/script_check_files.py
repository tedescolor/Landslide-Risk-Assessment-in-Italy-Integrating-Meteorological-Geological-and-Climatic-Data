import os
import itertools
import netCDF4

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

all_params = list(itertools.product(years, months, variable_verticals))
corrupted_files = []
missing_files = []
for params in all_params:
    year, month, var_vertical = params
    var, vertical = var_vertical
    # Include vertical in the filename
    filename = f"era5downscaled_{var}_vertical_{vertical}_{year}_{month}.nc"
    if not os.path.exists(filename):
        missing_files.append(filename)
        print(f"Failed to find file {filename}")
    else:
        try:
            # Attempt to open the file
            with netCDF4.Dataset(filename, 'r') as dataset:
                # You can perform additional checks here if necessary
                pass
            #print(f"File {filename} is OK.")
        except Exception as e:
            # If an error occurs, add the file to the list of corrupted files
            corrupted_files.append(filename)
            print(f"Failed to open file {filename}: {e}. ")
            # Delete the corrupted file
            #os.remove(file_path)

print(corrupted_files)
print(missing_files)





    

